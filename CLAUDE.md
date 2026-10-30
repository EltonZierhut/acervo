# Acervo

Organizador pessoal modular. Backend Rails 8 API + PostgreSQL em `api/`, frontend React +
TypeScript (Vite) em `web/`. Primeiro módulo: **Códigos** (snippets e projetos com busca).

Princípios do projeto: `.specify/memory/constitution.md`. Leia antes de planejar ou implementar.

## Idioma

- Responda, escreva specs, documentação, mensagens da interface e commits em **português do Brasil**.
- Código (classes, métodos, variáveis, tabelas, rotas da API) em **inglês**.

## Comandos

```bash
# Banco
docker compose up -d                 # PostgreSQL (postgres/postgres)

# Backend (api/)
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server                     # http://localhost:3000
bin/rails test                       # testes
bin/rails db:migrate:redo            # confere se a migration é reversível

# Frontend (web/)
npm install
npm run dev                          # http://localhost:5173 (proxy /api → :3000)
npm run build                        # checa tipos + build
npm run lint
```

## Estrutura e convenções

- **Módulo no backend**: `app/models/<mod>.rb` (com `table_name_prefix`), `app/models/<mod>/`,
  `app/controllers/api/v1/<mod>/`, `namespace :<mod>` em `config/routes.rb` e registro em
  `config/modules.yml`. Referencie models do módulo com `::` (ex.: `::Codes::Snippet`) dentro
  dos controllers, que também ficam no namespace `Api::V1::Codes`.
- **Módulo no frontend**: `web/src/modules/<mod>/` com `api.ts`, `types.ts`, `pages/`,
  `components/` e `index.tsx` exportando um `OrganizerModule`; registrar em `modules/index.ts`.
- **Compartilhado**: concerns em `api/app/models/concerns/` (`Searchable`, `NormalizesTags`),
  helpers em `ApplicationController` (`render_errors`, `paginate`), e `web/src/core/`
  (`api.ts`, `hooks.ts`, `Layout.tsx`). Módulos não importam uns dos outros.
- **Busca**: coluna `searchable` (tsvector gerada, `stored: true`) + índice GIN e
  `include Searchable` com `searchable_partial_columns`. Em colunas geradas use
  `immutable_array_to_string` para arrays (já existe no banco).
- **Schema** em SQL (`db/structure.sql`), não `schema.rb`.
- Com `verbatimModuleSyntax`, importe tipos com `import type`.

## Spec Kit

Fluxo para features novas (skills em `.claude/skills/`):

1. `/speckit-specify <descrição>`: cria a branch e `specs/NNN-nome/spec.md`
2. `/speckit-clarify`: opcional, tira dúvidas antes do plano
3. `/speckit-plan`: `plan.md`, modelo de dados, contratos da API
4. `/speckit-tasks`: `tasks.md`
5. `/speckit-analyze`: opcional, checa consistência entre spec, plano e tarefas
6. `/speckit-implement`: executa as tarefas

Ajustes pequenos podem ser feitos direto, sem spec. Antes de concluir uma tarefa, rode os
testes, o build e o lint da parte alterada.
