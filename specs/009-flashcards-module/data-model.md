# Modelo de dados: Módulo Flashcards (fase 1)

Quatro tabelas com prefixo `flashcards_`, sem `user_id` (uso pessoal, ver constituição). Uma migration
reversível por `change`.

## flashcards_decks

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `name` | string, não nulo | 1 a 100 caracteres; índice único em `lower(name)` |
| `description` | text | opcional, até 10 KB |
| `new_per_day` | integer, não nulo, padrão 20 | 0 a 9999 (`CHECK`) |
| `reviews_per_day` | integer, não nulo, padrão 200 | 0 a 9999 (`CHECK`) |
| timestamps | | |

## flashcards_notes

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `deck_id` | FK → decks, `ON DELETE CASCADE` | índice |
| `note_type` | string, não nulo, padrão `basic` | `basic` ou `basic_reversed` (`CHECK`) |
| `front`, `back` | text, não nulo | obrigatórios, Markdown, até 100 KB |
| `tags` | string[], não nulo, padrão `{}` | `NormalizesTags` |
| `suspended` | boolean, não nulo, padrão false | |
| `tags_text` | gerada (`immutable_array_to_string`) | para ILIKE |
| `searchable` | tsvector gerada | frente e tags peso A, verso peso B; índice GIN |
| timestamps | | |

Busca: `Searchable` com `searchable_partial_columns :front, :back, :tags_text`.

## flashcards_cards

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `note_id` | FK → notes, `ON DELETE CASCADE` | único com `ordinal` |
| `ordinal` | integer, não nulo | 0 = frente → verso; 1 = verso → frente |
| `state` | string, não nulo, padrão `new` | `new`, `learning`, `review`, `relearning` (`CHECK`) |
| `due_at` | datetime | nulo enquanto novo |
| `interval_days` | integer, não nulo, padrão 0 | |
| `ease` | integer, não nulo, padrão 2500 | facilidade em milésimos (2500 = 2,5) |
| `step_index` | integer, não nulo, padrão 0 | passo atual de (re)aprendizado |
| `reps`, `lapses` | integer, não nulo, padrão 0 | |
| `last_reviewed_at` | datetime | |
| timestamps | | |

Índice em `(state, due_at)` para a fila.

## flashcards_reviews

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `card_id` | FK → cards, `ON DELETE CASCADE` | índice com `reviewed_at` |
| `rating` | integer, não nulo | 1 a 4 (`CHECK`) |
| `state_before` | string, não nulo | |
| `interval_before`, `interval_after` | integer, não nulo | dias; 0 nos passos em minutos |
| `ease_after` | integer, não nulo | |
| `duration_ms` | integer | 0 a 3.600.000 (limitado no model) |
| `reviewed_at` | datetime, não nulo | |
| `created_at` | datetime | |

Imutável: o model não permite `update`.

## Contagens do dia

- **Dia de estudo**: de hoje às 4h até amanhã às 4h (America/Sao_Paulo); antes das 4h, vale o dia anterior.
- **Novos de hoje**: `min(cartões novos não suspensos, new_per_day − revisões de hoje com state_before = new)`.
- **Revisões de hoje**: `min(cartões em revisão vencidos até o fim do dia, reviews_per_day − revisões de hoje com state_before = review)`.
- **Aprendizado**: cartões em `learning` ou `relearning` com `due_at` até o fim do dia (sem limite).
