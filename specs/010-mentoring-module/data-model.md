# Modelo de dados: Módulo Mentoria (fase 1)

Sete tabelas com prefixo `mentoring_`, sem `user_id` (uso pessoal, ver constituição). Uma migration reversível por
`change`. Toda tabela filha apaga em cascata com a mentoria.

## mentoring_mentorships

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentor_name` | string, não nulo | 1 a 100 caracteres |
| `topic` | string | até 200 |
| `description` | text | Markdown, até 100 KB |
| `started_on` | date, não nulo | padrão hoje (no model) |
| `ended_on` | date | não antes de `started_on` |
| `cadence` | string | até 100 |
| `status` | string, não nulo, padrão `active` | `active`, `paused`, `finished` (`CHECK`) |
| timestamps | | |

## mentoring_questions

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentorship_id` | FK, `ON DELETE CASCADE` | índice com `position` |
| `position` | integer, não nulo | 1, 2, 3… na mentoria |
| `prompt` | text, não nulo | 1 a 500 caracteres |
| `answer` | text | Markdown, até 100 KB; respondida = não vazia |
| timestamps | | |

## mentoring_goals

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentorship_id` | FK, `ON DELETE CASCADE` | índice |
| `title` | string, não nulo | 1 a 200 |
| `success_criteria`, `description` | text | Markdown, até 100 KB |
| `target_on` | date | |
| `status` | string, não nulo, padrão `not_started` | `not_started`, `in_progress`, `achieved`, `dropped` (`CHECK`) |
| `progress` | integer, não nulo, padrão 0 | 0 a 100 (`CHECK`); `achieved` força 100 |
| timestamps | | |

## mentoring_meetings

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentorship_id` | FK, `ON DELETE CASCADE` | índice com `held_on` |
| `held_on` | date, não nulo | padrão hoje |
| `agenda`, `notes`, `takeaways` | text | Markdown, até 100 KB cada |
| `rating` | integer | 1 a 5 (`CHECK`), opcional |
| `tags` | string[], não nulo, padrão `{}` | `NormalizesTags` |
| `tags_text` | gerada (`immutable_array_to_string`) | para ILIKE |
| `searchable` | tsvector gerada | pauta e tags peso A, aprendizados B, anotações C; índice GIN |
| timestamps | | |

Busca: `Searchable` com `searchable_partial_columns :agenda, :notes, :takeaways, :tags_text`.

## mentoring_action_items

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentorship_id` | FK, `ON DELETE CASCADE` | índice |
| `meeting_id` | FK → meetings, `ON DELETE SET NULL` | índice; mesma mentoria |
| `goal_id` | FK → goals, `ON DELETE SET NULL` | índice; mesma mentoria |
| `title` | string, não nulo | 1 a 200 |
| `due_on` | date | |
| `completed_at` | datetime | nulo = aberta |
| timestamps | | |

Ordem da lista: abertas primeiro, por `due_on` (sem prazo no fim) e `id`; depois concluídas, mais recentes primeiro.

## mentoring_competencies

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `mentorship_id` | FK, `ON DELETE CASCADE` | |
| `name` | string, não nulo | 1 a 100; índice único em `(mentorship_id, lower(name))` |
| `position` | integer, não nulo | ordem de criação |
| timestamps | | |

## mentoring_ratings

| Coluna | Tipo | Regras |
| --- | --- | --- |
| `competency_id` | FK, `ON DELETE CASCADE` | único com `rated_on` |
| `rated_on` | date, não nulo | |
| `score` | integer, não nulo | 1 a 5 (`CHECK`) |
| `comment` | text | até 1.000 |
| timestamps | | |

Uma autoavaliação é o conjunto de notas de uma mesma data.
