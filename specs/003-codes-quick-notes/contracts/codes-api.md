# Contrato da API: notas do módulo Códigos

Base: `/api/v1/codes`. Todas as rotas exigem login e, na escrita, `Content-Type: application/json`.

## `GET /snippets`

Parâmetros: `q`, `tag`, `language`, `page`, `per_page`. Sai `project_id`.

```json
{
  "data": [
    {
      "id": 1,
      "title": null,
      "display_title": "pg_dump -Fc acervo_development > backup.dump",
      "language": "bash",
      "tags": ["postgres"],
      "created_at": "2026-10-30T10:00:00-03:00",
      "updated_at": "2026-10-30T10:00:00-03:00"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 1, "total_pages": 1 }
}
```

A listagem não traz `content` nem `description`.

## `GET /snippets/:id`

Item da listagem mais `content` e `description`. Inexistente: `404` com `{ "error": "..." }`.

## `POST /snippets` e `PATCH /snippets/:id`

```json
{ "snippet": { "content": "obrigatório no POST", "title": null, "language": null, "description": null, "tags": "a, b" } }
```

- Só `content` é obrigatório. `tags` aceita texto ou array. `project_id` deixa de ser aceito.
- Sucesso: `201` (`POST`) ou `200` (`PATCH`), com o mesmo corpo de `GET /snippets/:id`.
- Conteúdo vazio, só com espaços, acima de 1 MB, com byte nulo ou além do limite de indexação:
  `422` com `{ "errors": [...], "fields": { "content": [...] } }`. A versão anterior é mantida.

## `DELETE /snippets/:id`

`204` sem corpo.

## Removidas

`/projects` (todas as ações) e `/search`. Passam a responder `404`.
