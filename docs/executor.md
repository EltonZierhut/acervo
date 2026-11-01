# Executor do Acervo

O executor roda no seu computador. Ele busca as tarefas na fila do Acervo, desenvolve cada uma com o
Claude Code em um container descartável e abre o pull request. A fila só anda com o computador ligado e o
executor aberto; as tarefas enviadas nesse meio-tempo ficam aguardando.

## Requisitos

Ruby 3.2 ou mais novo, Git com nome e e-mail configurados, Docker, [GitHub CLI](https://cli.github.com/) e Claude Code.

## Instalação

```bash
# 1. Imagem do agente
docker build -t acervo-agent executor/

# 2. Acesso ao GitHub: o executor alcança o que esta conta alcançar
gh auth login

# 3. Token do Claude para o container
claude setup-token

# 4. Token do executor (mostrado uma vez; gerar outro invalida o anterior)
bin/prod-rails acervo:executor:create
```

Crie `~/.config/acervo-executor/config.yml` com os dois tokens:

```yaml
api_url: https://endereco-do-acervo
executor_token: "..."
claude_oauth_token: "..."
# Opcionais:
# max_budget_usd: 5          # limite de gasto por execução; sem ele, só vale o limite de 60 minutos
# image: acervo-agent:latest
# images:
#   dono/repositorio: minha-imagem:1
```

```bash
chmod 600 ~/.config/acervo-executor/config.yml
executor/bin/acervo-executor check   # confere tudo, sem executar tarefas
executor/bin/acervo-executor run     # processa a fila até receber Ctrl+C
```

Registros de cada execução: `~/.local/state/acervo-executor/runs/`.

## Repositórios

Em uma iniciativa, informe o repositório na aba **Detalhes**. O executor confere o acesso na próxima consulta, em até 30 segundos.
A conta do `gh` precisa ter permissão de escrita. Em organizações, confira se as regras delas permitem enviar o código à IA.

A imagem padrão traz Git, Node, Ruby, Python e ferramentas de compilação. Se um projeto precisar de mais para rodar os testes, crie uma imagem a
partir dela e indique em `images`. Quando os testes não rodam, o PR informa isso.

## O que protege o que

| Proteção | Como funciona |
|----------|---------------|
| A IA não escreve no GitHub | O container não recebe credenciais do GitHub. Commit, push e PR são feitos pelo executor, fora dele |
| Nada de merge nem push na branch padrão | O executor só cria uma branch nova e um PR. O merge é sempre seu |
| Arquivos da máquina | O container só enxerga o clone temporário e os anexos, com capacidades do Linux removidas |
| Hooks maliciosos | O `.git` fica só para leitura no container, e os hooks ficam desligados no Git da máquina |
| Workflows do repositório | Alterações em `.github/workflows/` fazem a execução falhar, sem publicar nada |

## Riscos que continuam

- **Vazamento:** o container tem internet e o token do Claude. Um link ou repositório malicioso pode induzir a IA a enviar para fora o código do
  repositório ou esse token. Tenha cuidado com links e repositórios de terceiros, e revogue o token se houver suspeita.
- **Código ruim no PR:** a IA pode errar ou ser induzida a erro. Revise todo PR antes do merge.
- **Gasto:** sem `max_budget_usd`, não há limite de gasto por execução, só o de 60 minutos.

## Problemas comuns

| Sintoma | O que fazer |
|---------|-------------|
| Fila parada e "Executor indisponível" | Abra o `acervo-executor run` |
| Repositório "Sem acesso" | Rode `gh auth login` com uma conta que tenha escrita e clique em "Verificar de novo" |
| Falha por interrupção | O executor parou no meio. Abra-o de novo e reenvie a tarefa |
| "Token do executor inválido" | Gere outro com `bin/prod-rails acervo:executor:create` e atualize a configuração |
