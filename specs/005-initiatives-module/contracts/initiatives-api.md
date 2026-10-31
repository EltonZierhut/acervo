# Contrato da API: módulo Iniciativas

Base: `/api/v1/initiatives`. Todas as rotas exigem login (401 `{ "error": "Não autenticado" }`).
Escritas exigem `Content-Type: application/json`. Erros de validação: `422
{ "errors": [...], "fields": { "campo": [...] } }`. Inexistente: `404 { "error": "Registro não encontrado" }`.
Datas: `"YYYY-MM-DD"`; instantes: ISO 8601.

## Contextos

### `GET /contexts`

`200` — array ordenado por nome:

```json
[{ "id": 1, "name": "Trabalho", "color": "#2f6fed", "initiatives_count": 3 }]
```

### `POST /contexts` — `{ "context": { "name": "Jogo", "color": "#7c3aed" } }`

`201` com o contexto (mesmo formato do item acima). `422` para nome vazio, repetido ou cor inválida.

### `PATCH /contexts/:id` — mesmos campos, todos opcionais. `200`.

### `DELETE /contexts/:id` — `204`; iniciativas do contexto ficam sem contexto.

## Iniciativas

### `GET /initiatives`

Parâmetros: `q` (busca), `status` (um status ou `all`; sem ele, todas menos `done`),
`context_id` (número ou `none`), `page`, `per_page` (1–100, padrão 20).

`200`:

```json
{
  "data": [{
    "id": 1, "name": "Jogo para a Steam", "status": "active", "priority": "high",
    "starts_on": "2026-11-01", "due_on": null, "tags": ["godot"],
    "context": { "id": 2, "name": "Jogo", "color": "#7c3aed" },
    "progress": { "done": 1, "total": 3 },
    "created_at": "...", "updated_at": "..."
  }],
  "meta": { "page": 1, "per_page": 20, "total": 1, "total_pages": 1 }
}
```

`context` é `null` sem contexto. Ordem conforme `data-model.md` (com `q`, relevância primeiro).

### `GET /initiatives/:id`

`200` — item da listagem mais `description` (string ou `null`) e `sections` (array, na ordem
`["tasks", "milestones"]`).

### `POST /initiatives`

```json
{ "initiative": { "name": "Reforma", "description": "...", "context_id": 2, "status": "planned",
  "priority": "medium", "starts_on": "2026-11-01", "due_on": "2026-12-20",
  "tags": "casa, obra", "sections": ["tasks"] } }
```

Só `name` é obrigatório. `tags` aceita array ou texto separado por vírgulas. `sections` omitido usa
todas. `201` com o detalhe. `422` para nome vazio, status/prioridade/seção inválidos, `due_on`
anterior a `starts_on` ou `context_id` inexistente.

### `PATCH /initiatives/:id` — mesmos campos, parciais. `200` com o detalhe.

### `DELETE /initiatives/:id` — `204`; apaga marcos e tarefas.

## Marcos

### `GET /initiatives/:initiative_id/milestones`

`200` — `{ "data": [milestone] }`, ordenado por `due_on` (sem data por último):

```json
{ "id": 4, "initiative_id": 1, "title": "Protótipo jogável", "description": null,
  "due_on": "2027-02-01", "completed_at": null, "progress": { "done": 1, "total": 2 },
  "created_at": "...", "updated_at": "..." }
```

### `POST /initiatives/:initiative_id/milestones`

`{ "milestone": { "title": "...", "description": "...", "due_on": "...", "completed": false } }` →
`201`. Só `title` é obrigatório.

### `PATCH /milestones/:id` — mesmos campos, parciais; `completed: true` grava `completed_at`. `200`.

### `DELETE /milestones/:id` — `204`; tarefas ficam sem marco.

## Tarefas

### `GET /initiatives/:initiative_id/tasks`

Parâmetros: `q`, `status`, `milestone_id` (número ou `none`).

`200`:

```json
{
  "data": [{
    "id": 9, "initiative_id": 1, "milestone_id": 4, "title": "Movimento do personagem",
    "description": null, "status": "doing", "priority": "medium", "due_on": "2026-11-15",
    "completed_at": null, "created_at": "...", "updated_at": "..."
  }],
  "meta": { "total": 1, "truncated": false }
}
```

Ordem conforme `data-model.md` (com `q`, relevância primeiro). No máximo 1.000 itens;
`truncated: true` indica que há mais.

### `POST /initiatives/:initiative_id/tasks`

`{ "task": { "title": "...", "description": "...", "status": "todo", "priority": "medium",
"due_on": "...", "milestone_id": 4 } }` → `201` com a tarefa. Só `title` é obrigatório.
`422` para marco de outra iniciativa.

### `PATCH /tasks/:id` — mesmos campos, parciais. `200`.

### `DELETE /tasks/:id` — `204`.

## Módulos

`GET /api/v1/modules` passa a incluir `{ "key": "initiatives", "name": "Iniciativas", ... }`.
