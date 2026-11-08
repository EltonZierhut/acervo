# Contrato da API: Módulo Flashcards (fase 1)

Base: `/api/v1/flashcards`. Todas as rotas exigem login. Erros de validação: `422 { errors, fields }`;
registro inexistente: `404 { error }`.

## Baralhos

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /decks` | | `200 { data: Deck[] }` (ordem alfabética, sem paginação) |
| `GET /decks/:id` | | `200 Deck` |
| `POST /decks` | `{ deck: { name, description?, new_per_day?, reviews_per_day? } }` | `201 Deck` |
| `PATCH /decks/:id` | mesmo formato | `200 Deck` |
| `DELETE /decks/:id` | | `204` |

```json
{
  "id": 1, "name": "Inglês", "description": null, "new_per_day": 20, "reviews_per_day": 200,
  "card_count": 42, "due": { "new": 20, "learning": 2, "review": 13 },
  "created_at": "2026-11-07T21:00:00-03:00", "updated_at": "2026-11-07T21:00:00-03:00"
}
```

## Notas

| Método e rota | Corpo / parâmetros | Resposta |
| --- | --- | --- |
| `GET /decks/:deck_id/notes` | `q`, `tag`, `page`, `per_page` | `200 { data: Note[], meta }` (mais recentes primeiro; com `q`, por relevância) |
| `POST /decks/:deck_id/notes` | `{ note: { note_type?, front, back, tags? } }` | `201 Note` |
| `GET /notes/:id` | | `200 Note` |
| `PATCH /notes/:id` | `{ note: { note_type?, front?, back?, tags?, deck_id?, suspended? } }` | `200 Note` |
| `POST /notes/:id/reset` | | `200 Note` (cartões voltam a novos; histórico mantido) |
| `DELETE /notes/:id` | | `204` |

`tags` aceita array ou texto separado por vírgulas.

```json
{
  "id": 7, "deck_id": 1, "note_type": "basic_reversed", "front": "**dog**", "back": "cachorro",
  "tags": ["animais"], "suspended": false,
  "cards": [
    { "id": 11, "ordinal": 0, "state": "review", "due_at": "2026-11-10T04:00:00-03:00", "interval_days": 3, "ease": 2500, "reps": 4, "lapses": 0 },
    { "id": 12, "ordinal": 1, "state": "new", "due_at": null, "interval_days": 0, "ease": 2500, "reps": 0, "lapses": 0 }
  ],
  "created_at": "…", "updated_at": "…"
}
```

## Estudo

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /decks/:deck_id/study` | | `200 Study` |
| `POST /cards/:id/review` | `{ rating: 1..4, duration_ms? }` | `200 Study` (já com o próximo cartão); `422` se a nota for inválida ou o cartão estiver suspenso |

```json
{
  "deck": { "id": 1, "name": "Inglês" },
  "counts": { "new": 19, "learning": 1, "review": 12 },
  "card": {
    "id": 12, "note_id": 7, "ordinal": 1, "state": "new",
    "question": "cachorro", "answer": "**dog**", "tags": ["animais"],
    "intervals": { "1": "1 min", "2": "6 min", "3": "10 min", "4": "4 dias" }
  },
  "next_due_at": null,
  "due_tomorrow": 8
}
```

- `card` é `null` quando não há nada a estudar agora. Nesse caso, `next_due_at` traz o vencimento do próximo
  cartão em aprendizado ainda hoje (ou `null`), e `due_tomorrow` quantos cartões vencem no próximo dia de estudo.
- `question`/`answer`: frente e verso da nota, invertidos quando `ordinal = 1`. Markdown.
- `intervals`: texto do intervalo que cada resposta dará ("1 min", "1 h", "1 dia", "3 meses", "1,2 ano").
