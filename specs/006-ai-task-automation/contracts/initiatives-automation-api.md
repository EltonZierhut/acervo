# Contrato da API: automação no módulo Iniciativas (interface)

Base: `/api/v1/initiatives`. Exige login e segue as convenções de `specs/005-initiatives-module/contracts/initiatives-api.md`.

## Repositório

`PATCH /initiatives/:id` passa a aceitar `github_repository` (`null` remove). O JSON da iniciativa ganha `github_repository`, `repository_status`,
`repository_error` e `repository_checked_at`.

`POST /initiatives/:id/verify_repository`: volta para `unverified`. `200` com a iniciativa; `422` sem repositório.

## Imagens

- `GET /tasks/:task_id/task_images`: `200 [{ "id", "filename", "content_type", "byte_size", "url" }]`.
- `POST /tasks/:task_id/task_images?filename=tela.png`: corpo com os bytes e `Content-Type: image/*`. `201` com o item. `422` para tipo, tamanho ou
  limite por tarefa. `415` para outro `Content-Type`.
- `GET /task_images/:id`: os bytes, com `X-Content-Type-Options: nosniff` e `Cache-Control: private`.
- `DELETE /task_images/:id`: `204`.

## Links

- `GET /tasks/:task_id/task_links`: `200 [{ "id", "url", "title" }]`.
- `POST /tasks/:task_id/task_links`: `{ "task_link": { "url", "title" } }`. `201`; `422` para URL inválida.
- `PATCH /task_links/:id`: `200`. `DELETE /task_links/:id`: `204`.

## Execuções

Formato de uma execução:

```json
{
  "id": 7, "task_id": 3, "task_title": "Corrigir login", "initiative_id": 2, "initiative_name": "Jogo",
  "repository": "owner/name", "status": "waiting", "enqueued_at": "...", "started_at": "...", "finished_at": null,
  "failure_kind": null, "failure_reason": null, "summary": null, "pull_request_url": null,
  "questions": [{ "id": 1, "body": "Qual tela?", "answer": null, "answered_at": null }]
}
```

- `POST /tasks/:task_id/runs`: envia para a fila. `201`. `422` sem descrição, sem repositório, com repositório `invalid` ou já ativa.
- `GET /tasks/:task_id/runs`: `200`, histórico da tarefa, mais recente primeiro.
- `GET /runs?status=&q=&page=&per_page=`: `200 { "data": [...], "meta": {...} }`. Ativas primeiro, por `enqueued_at`; depois finais, mais recentes primeiro.
- `POST /runs/:id/cancel`: `200`. `422` se já estiver em estado final.
- `POST /runs/:id/answers`: `{ "answers": [{ "question_id": 1, "answer": "Tela de login" }] }`. `200`; volta para `queued` quando não falta resposta. `422` se a
  execução não estiver em `waiting` ou com resposta vazia.

O JSON da tarefa ganha `images_count`, `links_count` e `latest_run` (resumo com `id`, `status`, `pull_request_url`).

## Executor

`GET /executor_status`: `200 { "available": true, "last_seen_at": "...", "configured": true }`.
