# Contrato da API: executor

Base: `/api/v1/initiatives/executor`. Toda rota exige `Authorization: Bearer <token>`; sem ele, ou com token inválido, `401 { "error": "Não autenticado" }`. Não
aceita cookie de sessão. Toda chamada atualiza `last_seen_at`. Escritas em JSON.

## `POST /claim` — `{ "version": "1.0.0" }`

`204` sem trabalho. `200` com o conteúdo do momento em que a execução começa:

```json
{
  "run": {
    "id": 7, "repository": "owner/name",
    "task": { "id": 3, "title": "...", "description": "..." },
    "images": [{ "id": 1, "filename": "tela.png", "content_type": "image/png" }],
    "links": [{ "url": "https://...", "title": "..." }],
    "questions": [{ "body": "...", "answer": "..." }]
  }
}
```

Marca execuções sem heartbeat como `failed`/`interrupted` antes de escolher. Responde `204` se já houver outra em `running`.

## `GET /images/:id`

Os bytes. Só para imagens de tarefa com execução em `running`; caso contrário, `404`.

## `POST /runs/:id/heartbeat`

`200 { "cancel": false }`. `200 { "cancel": true }` se cancelada. `404` se a tarefa foi apagada; o executor interrompe do mesmo modo.

## `POST /runs/:id/questions` — `{ "questions": ["..."] }`

`running` → `waiting`. `200`. `409` se não estiver em `running`.

## `POST /runs/:id/complete`

```json
{ "status": "pr_open", "summary": "...", "branch": "acervo/task-3-run-7", "pull_request_url": "https://github.com/..." }
```

`status`: `pr_open`, `no_changes` ou `failed` (com `failure_kind` e `failure_reason`). `200`. Idempotente: repetir o mesmo resultado responde `200`. Em execução cancelada,
guarda `pull_request_url`, se houver, sem mudar o estado. O formato de `pull_request_url` é validado e o repositório precisa ser o da execução.

## `GET /repository_checks`

`200 { "repositories": ["owner/name"] }`: repositórios em `unverified`.

## `POST /repository_checks` — `{ "repository": "owner/name", "valid": false, "error": "..." }`

Atualiza todas as iniciativas com esse repositório. `200`.
