# Modelo de dados: Execução de tarefas por IA até o pull request

Migrations só aditivas e reversíveis. Exclusões em cascata por chave estrangeira.

## `initiatives_initiatives` (colunas novas)

| Campo | Tipo | Regras |
|-------|------|--------|
| `github_repository` | string, nulo | `owner/name`; formato validado; aceita URL do GitHub e normaliza. Nulo = sem conexão |
| `repository_status` | string, padrão `unverified` | `unverified`, `valid`, `invalid` |
| `repository_error` | text, nulo | Motivo em português, quando `invalid` |
| `repository_checked_at` | datetime, nulo | |

Alterar `github_repository` volta o status para `unverified`. Um repositório pode ser usado por mais de uma iniciativa.

## `initiatives_task_images`

| Campo | Tipo | Regras |
|-------|------|--------|
| `task_id` | FK, cascata | |
| `filename` | string | Até 255 caracteres, sem caminho |
| `content_type` | string | `image/png`, `image/jpeg`, `image/webp`, `image/gif`, conferido pelos bytes |
| `byte_size` | integer | Até 10 MB |
| `position` | integer | Ordem de envio |
| `data` | binary | Nunca carregado em listagens (escopo com `select` explícito) |

Até 10 por tarefa, com a contagem protegida por bloqueio da tarefa.

## `initiatives_task_links`

| Campo | Tipo | Regras |
|-------|------|--------|
| `task_id` | FK, cascata | |
| `url` | text | `http` ou `https`, até 2.048 caracteres |
| `title` | string, nulo | Até 200 caracteres |
| `position` | integer | |

## `initiatives_runs`

| Campo | Tipo | Regras |
|-------|------|--------|
| `task_id` | FK, cascata | |
| `repository` | string | Copiado da iniciativa ao entrar na fila (edição posterior não afeta) |
| `status` | string | Ver transições |
| `enqueued_at` | datetime | Mantido ao voltar da espera, o que preserva a posição (FR-013a) |
| `started_at`, `finished_at`, `last_heartbeat_at` | datetime, nulo | `started_at` é refeito a cada retomada |
| `failure_reason` | text, nulo | Mensagem em português |
| `failure_kind` | string, nulo | `interrupted`, `timeout`, `repository`, `agent`, `workflow_change`, `other` |
| `summary` | text, nulo | Resumo do resultado; explicação em `no_changes` |
| `pull_request_url` | string, nulo | |
| `branch` | string, nulo | |

**Índices**: único parcial em `task_id` onde `status IN ('queued','running','waiting')`; único parcial em `(status)` onde
`status = 'running'`; `(status, enqueued_at)`.

**Transições**:

```text
queued  -> running   claim
queued  -> canceled  usuário, tarefa concluída manualmente
running -> pr_open | no_changes | failed   executor
running -> waiting   executor registra perguntas
running -> canceled  usuário (status vira canceled; o heartbeat seguinte manda parar)
running -> failed    sem heartbeat por 5 min (interrupted)
waiting -> queued    todas as perguntas respondidas
waiting -> canceled  usuário
```

`pr_open`, `no_changes`, `failed` e `canceled` são finais; reenviar cria outra `Run`. Um resultado recebido depois de `canceled`
é ignorado, salvo PR já aberto, cujo link é guardado para não perder a referência.

**Efeito na tarefa**: ao entrar em `pr_open`, tarefa `todo` passa a `doing` (FR-020). Tarefa marcada `done` cancela a `Run` em `queued` ou `waiting`.

## `initiatives_run_questions`

| Campo | Tipo | Regras |
|-------|------|--------|
| `run_id` | FK, cascata | |
| `body` | text | Obrigatório |
| `answer` | text, nulo | Preenchido uma vez, até 10.000 caracteres |
| `answered_at` | datetime, nulo | |

## `initiatives_executors`

| Campo | Tipo | Regras |
|-------|------|--------|
| `token_digest` | string | SHA-256; único |
| `last_seen_at` | datetime, nulo | Atualizado no máximo a cada 15 s |
| `version` | string, nulo | Versão do executor |

Uma linha só: criar um token substitui o anterior. Disponível = `last_seen_at` há menos de 2 min.
