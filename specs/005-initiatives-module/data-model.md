# Modelo de dados: Módulo Iniciativas (fase 1)

Todas as tabelas usam o prefixo `initiatives_` (`Initiatives.table_name_prefix`). Datas de
calendário são `date`; instantes são `timestamp` (fuso `America/Sao_Paulo` na aplicação).

```text
initiatives_contexts 1 ── * initiatives_initiatives 1 ── * initiatives_milestones
                                         │                         │ 0..1
                                         └──────── * initiatives_tasks ─┘
```

## `initiatives_contexts` — `Initiatives::Context`

| Coluna | Tipo | Regras |
|--------|------|--------|
| `name` | string | obrigatório, até 60 caracteres, sem espaços nas pontas; único sem diferenciar maiúsculas (índice em `lower(name)`) |
| `color` | string | obrigatório, `#rrggbb` minúsculo; padrão `#6b7380` |
| timestamps | | |

- `has_many :initiatives, dependent: :nullify` (a FK também é `ON DELETE SET NULL`).

## `initiatives_initiatives` — `Initiatives::Initiative`

| Coluna | Tipo | Regras |
|--------|------|--------|
| `context_id` | bigint, FK | opcional; `ON DELETE SET NULL` |
| `name` | string | obrigatório, até 200 caracteres, sem espaços nas pontas |
| `description` | text | opcional; em branco vira `null` |
| `status` | string | `idea`, `planned` (padrão), `active`, `paused`, `done`; `CHECK` no banco |
| `priority` | string | `low`, `medium` (padrão), `high`; `CHECK` no banco |
| `starts_on` | date | opcional |
| `due_on` | date | opcional; `>= starts_on` quando ambos existem (`CHECK` e validação) |
| `tags` | string[] | padrão `{}`; `NormalizesTags` |
| `tags_text` | text gerada | `immutable_array_to_string(tags, ' ')`, para busca por pedaços |
| `sections` | string[] | subconjunto de `SECTIONS = %w[tasks milestones]`; padrão todas; sem repetição, na ordem de `SECTIONS` |
| `searchable` | tsvector gerada | `name` e `tags` peso A, `description` peso B |
| timestamps | | `updated_at` também muda quando tarefas ou marcos mudam (`touch`) |

Índices: GIN em `searchable` e `tags`; trigram em `name`; `status`; `context_id`.

- `belongs_to :context, optional: true`
- `has_many :milestones, dependent: :delete_all` e `has_many :tasks, dependent: :delete_all`
  (FKs com `ON DELETE CASCADE`)
- `include Searchable` com `searchable_partial_columns :name, :description, :tags_text`
- Escopos: `open` (status ≠ `done`), `in_status`, `in_context`, `ordered`
  (ativa, planejada, ideia, pausada, encerrada; depois `updated_at DESC`), `with_progress`
  (adiciona `tasks_total` e `tasks_done` por subconsulta agregada).

## `initiatives_milestones` — `Initiatives::Milestone`

| Coluna | Tipo | Regras |
|--------|------|--------|
| `initiative_id` | bigint, FK | obrigatório; `ON DELETE CASCADE` |
| `title` | string | obrigatório, até 200 caracteres |
| `description` | text | opcional |
| `due_on` | date | opcional |
| `completed_at` | timestamp | preenchido por `completed = true`, limpo por `completed = false` |
| timestamps | | |

Índice: `(initiative_id, due_on)`.

- `belongs_to :initiative, touch: true`
- `has_many :tasks, dependent: :nullify` (FK `ON DELETE SET NULL`)
- Ordem: `due_on ASC NULLS LAST, created_at ASC`. Escopo `with_progress` como na iniciativa.
- `overdue?`: não concluído e `due_on < hoje`.

## `initiatives_tasks` — `Initiatives::Task`

| Coluna | Tipo | Regras |
|--------|------|--------|
| `initiative_id` | bigint, FK | obrigatório; `ON DELETE CASCADE` |
| `milestone_id` | bigint, FK | opcional; `ON DELETE SET NULL`; precisa ser da mesma iniciativa |
| `title` | string | obrigatório, até 300 caracteres |
| `description` | text | opcional |
| `status` | string | `todo` (padrão), `doing`, `done`; `CHECK` no banco |
| `priority` | string | `low`, `medium` (padrão), `high`; `CHECK` no banco |
| `due_on` | date | opcional |
| `completed_at` | timestamp | preenchido ao entrar em `done`, limpo ao sair |
| `searchable` | tsvector gerada | `title` peso A, `description` peso B |
| timestamps | | |

Índices: `(initiative_id, status)`, `milestone_id`, GIN em `searchable`, trigram em `title`.

- `belongs_to :initiative, touch: true`, `belongs_to :milestone, optional: true`
- `include Searchable` com `searchable_partial_columns :title, :description`
- Ordem (`ordered`): status (`doing`, `todo`, `done`); não concluídas por `due_on ASC NULLS LAST`,
  concluídas por `completed_at DESC`; desempate por `created_at`.
- `overdue?`: não concluída e `due_on < hoje`.

## Transições

- Tarefa: qualquer status ↔ qualquer status. Entrar em `done` grava `completed_at = agora` (se vazio);
  sair de `done` limpa.
- Marco: `completed` alterna `completed_at`.
- Iniciativa: qualquer status ↔ qualquer status; não há regra automática a partir das tarefas.
