# Plano de implementação: Execução de tarefas por IA até o pull request

**Branch**: `006-ai-task-automation` | **Data**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação em `specs/006-ai-task-automation/spec.md`

## Resumo

O módulo Iniciativas ganha imagens e links nas tarefas, conexão da iniciativa com um repositório e uma
fila de execuções guardada no PostgreSQL. Um programa executor no computador do usuário busca a fila pela
API, com token próprio. Para cada execução, ele clona o repositório, roda o Claude Code em um container
descartável e sem credenciais do GitHub, e ele mesmo, fora do container, faz commit, push e abre o PR. A IA
nunca recebe poder de escrita no GitHub, o que garante FR-017 pela arquitetura e não por instrução.

## Contexto técnico

**Linguagem/versão**: Ruby 3.2+ com Rails 8 (API); TypeScript com React 19 e Vite; executor em Ruby 3.2+

**Dependências principais**: nenhuma gem ou pacote npm novo. O executor usa só a biblioteca padrão do Ruby
e exige na máquina `git`, `gh` e Docker. A imagem do container instala o Claude Code CLI (ver Complexidade).

**Armazenamento**: PostgreSQL 16, com cinco tabelas novas e colunas novas em `initiatives_initiatives`.
Imagens em `bytea`, em tabela própria (ver `research.md`).

**Testes**: Minitest (models, request tests e executor com comandos externos simulados);
`npm run build` e `npm run lint`; validação ponta a ponta em `quickstart.md`

**Plataforma**: API em Cloud Run (uma instância e um processo); executor em Linux/WSL2 com Docker

**Tipo de projeto**: aplicação web (`api/` + `web/`) mais um programa de linha de comando (`executor/`)

**Metas de desempenho**: fila sem atraso perceptível, com consulta a cada 30 s (SC-001, SC-006)

**Restrições**: uma execução por vez (FR-009); 60 min por execução (FR-015); credenciais do GitHub fora do
servidor e do container (FR-007); migrations compatíveis com a versão anterior do código durante a troca

**Escala**: uso pessoal, uma conta e um executor

## Constitution Check

*Verificado antes da Fase 0 e novamente depois da Fase 1.*

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | OK | Tudo em `Initiatives::`, tabelas `initiatives_*`, controllers em `api/v1/initiatives/` e `web/src/modules/initiatives/`. O núcleo só ganha a extensão genérica do guard de Content-Type. `executor/` é cliente externo da API, sem código compartilhado. |
| II. Simplicidade | OK, com justificativas | Fila é tabela do PostgreSQL, sem gem nem serviço de filas; a necessidade concreta é FR-008 e FR-009. Programa externo e container estão em Complexidade. |
| III. Busca central | OK | A fila busca pelo título da tarefa (FR-021), reaproveitando `Searchable`, e é paginada. Imagens, links, execuções e perguntas são dados da tarefa, não entidades principais. |
| IV. API estável | OK | Rotas novas e campos novos, sem mudança incompatível. Erros no formato padrão. `types.ts` espelha o contrato. |
| V. Qualidade | OK | Testes de models, request tests e testes do executor, que entram no CI. Migrations reversíveis e só aditivas. |
| VI. Idioma | OK | Interface e mensagens em português; código e API em inglês. |

**Exceções combinadas com `CLAUDE.md`**: `allow_unauthenticated_access` nas rotas do executor tem motivo
explícito em FR-023; elas exigem token e respondem 401 sem ele, então o teste de rotas protegidas continua
valendo. O upload de imagem aceita `image/*` além de JSON; a proteção contra CSRF continua, porque um
formulário de outro site não consegue enviar esses tipos.

## Estrutura do projeto

### Documentação

```text
specs/006-ai-task-automation/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/initiatives-automation-api.md
├── contracts/executor-api.md
├── contracts/executor-cli.md
├── checklists/requirements.md
└── tasks.md                     # criado pelo /speckit-tasks
```

### Código-fonte

```text
api/
├── app/models/initiatives/{task_image,task_link,run,run_question,executor}.rb
├── app/models/initiatives/{initiative,task}.rb                # alterados
├── app/controllers/application_controller.rb                  # tipos aceitos por ação
├── app/controllers/api/v1/initiatives/{task_images,task_links,runs,run_answers,executor_status}_controller.rb
├── app/controllers/api/v1/initiatives/executor/{base,claims,heartbeats,runs,images,repository_checks}_controller.rb
├── lib/tasks/acervo_executor.rake                             # cria e troca o token
├── db/migrate/
└── test/{models,controllers}/initiatives/

executor/
├── bin/acervo-executor                                        # run, check, version
├── lib/acervo_executor/{client,loop,workspace,agent,publisher,config,spool}.rb
├── prompts/task.md.erb
├── Dockerfile                                                 # imagem padrão do agente
└── test/

web/src/modules/initiatives/
├── components/{TaskImages,TaskLinks,TaskRunPanel,RunQuestions,RepositoryField,ExecutorStatus}.tsx
├── pages/QueuePage.tsx                                        # /iniciativas/fila
├── api.ts, types.ts, labels.ts, index.tsx                     # alterados

docs/executor.md                                               # instalação e configuração
.github/workflows/ci.yml                                       # job dos testes do executor
```

**Decisão de estrutura**: mantém `api/` e `web/` e adiciona `executor/`, fora da imagem de produção, porque
ele roda na máquina do usuário e não no servidor.

## Riscos residuais

- **Exfiltração**: o container tem internet e o token do Claude. Um link ou repositório malicioso pode induzir
  a IA a enviar o código do repositório ou esse token para fora. As credenciais do GitHub e os arquivos da máquina
  ficam protegidos, mas isso não é eliminado nesta versão. Vale tratar links e repositórios de terceiros com
  cuidado e revogar o token do Claude se houver suspeita.
- **Código malicioso no PR**: a IA pode gerar código ruim, por isso o PR nunca recebe merge automático. Mudanças em
  `.github/workflows/` são recusadas (FR-024), para que um push não rode com os segredos do repositório.
- **Ferramentas do repositório**: a imagem padrão pode não ter tudo para rodar os testes de cada projeto. O PR
  informa quando os testes não rodaram, e o usuário pode indicar outra imagem por repositório.
- **Espaço no banco**: as imagens ocupam o disco de 10 GB do Cloud SQL. Se o volume crescer, migrar para um bucket.

## Complexidade

| Violação | Por que é necessária | Alternativa mais simples rejeitada porque |
|----------|----------------------|-------------------------------------------|
| Programa externo `executor/` | A execução no computador do usuário foi decidida em FR-011 | Rodar no Cloud Run não comporta execuções longas com uma instância, e foi descartado pelo usuário |
| Container Docker para o agente | A IA lê conteúdo não confiável e executa código do repositório sem supervisão; precisa ficar longe das credenciais e dos arquivos da máquina | Rodar direto na máquina deixaria `gh`, chaves SSH e arquivos pessoais ao alcance de uma instrução maliciosa |
| Claude Code CLI na imagem do agente | É o agente que desenvolve a tarefa | Construir um agente próprio sobre a API seria muito mais código |
