# Contrato: linha de comando do executor

```text
executor/bin/acervo-executor run       # processa a fila até receber Ctrl+C
executor/bin/acervo-executor check     # confere config, Docker, gh, imagem e API, sem executar tarefas
executor/bin/acervo-executor version
```

Códigos de saída: `0` normal; `1` erro de configuração, com a explicação em português.

Ao receber Ctrl+C durante uma execução, interrompe o container e informa `failed`/`interrupted`.

## Configuração: `~/.config/acervo-executor/config.yml` (permissão 600)

```yaml
api_url: https://acervo-egeq76vyaa-rj.a.run.app
executor_token: "..."          # bin/prod-rails acervo:executor:create
claude_oauth_token: "..."      # claude setup-token
image: acervo-agent:latest     # opcional
images:                        # opcional, por repositório
  owner/name: minha-imagem:1
max_budget_usd: 5              # opcional; sem valor, sem limite de gasto
```

O acesso ao GitHub vem do `gh auth login` da máquina. O executor não inicia se o arquivo tiver permissão mais aberta que 600.

## Saídas de cada execução

Registro em `~/.local/state/acervo-executor/runs/<run_id>.log`, sem credenciais. O clone temporário é apagado ao final.
