# Pesquisa: Execução de tarefas por IA até o pull request

Ferramentas conferidas na máquina em 2026-11-01: Ruby 3.2.3, Docker 29.1.3, `gh` 2.103.3 e Claude Code 2.1.316,
com `-p`, `--output-format`, `--json-schema`, `--max-budget-usd`, `--no-session-persistence`,
`--dangerously-skip-permissions` e `setup-token` disponíveis. A execução dentro do container ainda não foi testada.

## 1. Agente de IA

- **Decisão**: Claude Code CLI em modo não interativo (`claude -p`), com `--json-schema` para o resultado.
- **Motivo**: já está em uso pelo usuário, edita arquivos, roda comandos e lê imagens por caminho local.
- **Alternativas**: agente próprio sobre a API (muito mais código).

## 2. Isolamento do agente

- **Decisão**: container descartável por execução, sem credenciais do GitHub. `/workspace` é o clone, com
  `/workspace/.git` montado só para leitura. Sem Docker socket e sem pastas do usuário. O token do Claude vem de
  `claude setup-token`, por variável de ambiente. Dentro do container, o agente usa
  `--dangerously-skip-permissions`, porque não há ninguém para aprovar pedidos.
- **Motivo**: o conteúdo de links, imagens e repositório não é confiável. Com `.git` só para leitura, o agente não
  consegue criar hooks nem alterar a configuração que o Git da máquina usaria depois.
- **Alternativas**: sandbox do próprio CLI (isolamento depende da configuração da ferramenta); bloquear a internet
  (impediria ler links e instalar dependências).

## 3. Quem escreve no GitHub

- **Decisão**: o executor, fora do container: `git add`, `commit` e `push` com `core.hooksPath=/dev/null`, e `gh pr create`.
  Branch `acervo/task-<task_id>-run-<run_id>`. A base é a branch padrão do repositório. Usa o login do `gh` da máquina.
- **Motivo**: cumpre FR-017 e FR-007 sem depender do comportamento da IA, e o alcance é o que o usuário configurou
  (FR-006). O `gh` local já tem os escopos `repo` e `workflow`, por isso a recusa de `.github/workflows/` é feita
  pelo executor (FR-024), antes do push.
- **Alternativas**: GitHub App (configuração muito maior, sem ganho para uma conta); token por repositório no servidor
  (contraria a decisão de manter credenciais fora dele).

## 4. Fila

- **Decisão**: tabela `initiatives_runs`. O executor pede trabalho com `POST /claim`, atendido em transação, pela menor
  `enqueued_at`. Índices únicos parciais garantem uma execução ativa por tarefa e uma execução `running` no sistema.
- **Motivo**: PostgreSQL já existe; não há processo em segundo plano no Cloud Run.
- **Alternativas**: Solid Queue e similares (feitos para trabalho dentro do servidor, e o trabalho aqui é externo).

## 5. Comunicação do executor

- **Decisão**: o executor sempre inicia a conversa. Consulta a cada 30 s sem trabalho, e envia heartbeat a cada 30 s durante
  a execução; a resposta do heartbeat informa se deve cancelar. O servidor considera indisponível sem contato há 2 min e marca
  como falha por interrupção a execução sem heartbeat há 5 min, na próxima consulta à fila ou ao `claim`.
- **Motivo**: a máquina não precisa aceitar conexões. O Cloud Run não tem tarefas agendadas neste projeto.
- **Custo**: são cerca de 86 mil requisições por mês com o computador sempre ligado. O faturamento por requisição mantém o custo
  baixo, mas `--min-instances 0` deixa de desligar o serviço enquanto o executor está aberto. Conferir no primeiro mês.
- **Alternativas**: WebSocket (exige conexão longa e mais código).

## 6. Autenticação do executor

- **Decisão**: `Authorization: Bearer`, com token de 256 bits. O banco guarda só o SHA-256. Criado com
  `bin/prod-rails acervo:executor:create`, que mostra o token uma vez e invalida o anterior. Guardado em
  `~/.config/acervo-executor/config.yml`, com permissão 600.
- **Motivo**: sessão por cookie serve ao navegador e expira. O token só alcança as rotas `/executor`.
- **Alternativas**: reaproveitar o login com senha (exigiria guardar a senha na máquina).

## 7. Imagens

- **Decisão**: `bytea` em `initiatives_task_images`, com consultas que não carregam a coluna `data`. Upload com o corpo cru e
  `Content-Type: image/*`. O tipo real é conferido pelos primeiros bytes. Entrega com `nosniff` e cache privado. SVG não é aceito.
- **Motivo**: sem bucket, gem, papel de IAM ou credencial novos. Backup junto do banco e exclusão em cascata (FR-003). Volume baixo de
  uso pessoal. Corpo cru evita o acréscimo do base64 e mantém o guard contra CSRF.
- **Alternativas**: Active Storage com Cloud Storage (nova gem, bucket e IAM); disco do container (não é persistente no Cloud Run).

## 8. Retomar depois de uma pergunta

- **Decisão**: nova execução do agente em clone novo, na mesma `Run`, com o pedido e as perguntas e respostas no prompt.
- **Motivo**: a espera não tem prazo e a fila já foi liberada; a máquina pode reiniciar. Guardar o clone seria frágil.
- **Custo**: trabalho anterior é refeito, mas a IA só pergunta antes de abrir o PR, normalmente cedo.
- **Alternativas**: `--resume` da sessão (depende de estado local que pode ter sido apagado).

## 9. Resultado do agente

- **Decisão**: esquema JSON com `outcome` (`completed`, `needs_input`, `no_changes`), `summary`, `decisions`, `unread_links`, `tests`, `pr_title`
  e `questions`. O executor confere o resultado contra o `git status`: `completed` sem alterações vira `no_changes`, e `needs_input`
  descarta as alterações.
- **Motivo**: o estado final não depende de interpretar texto livre.

## 10. Modelo do PR

- **Decisão**: o executor lê `.github/pull_request_template.md`, quando existe, e passa ao agente no prompt. O agente devolve o corpo; o executor acrescenta o
  link da tarefa. O corpo vai por arquivo, com `--body-file`.

## 11. Entrega do resultado depois de abrir o PR

- **Decisão**: o executor grava o resultado em `~/.local/state/acervo-executor/` antes de informá-lo, e tenta de novo até o servidor confirmar. O `complete` é
  idempotente. Antes de criar o PR, procura um já aberto na mesma branch.
- **Motivo**: uma queda de rede entre abrir o PR e avisar o Acervo não pode gerar PR duplicado nem falha falsa.
