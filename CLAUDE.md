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
bin/rails acervo:user:create         # cria a conta (interativo; só uma nesta versão)
bin/rails acervo:user:reset_password # nova senha + encerra as sessões

# Frontend (web/)
npm install
npm run dev                          # http://localhost:5173 (proxy /api → :3000)
npm run build                        # checa tipos + build
npm run lint

# Produção (raiz)
docker build -t acervo .             # imagem única: React compilado + Rails
bin/deploy-gcp                       # publica no Cloud Run (guia: docs/deploy-gcp.md)
```

## Produção

- Uma imagem (`Dockerfile` na raiz) com API e interface. O build do React é dividido:
  `assets/` vai para `api/public/assets/` e o `index.html` para `api/frontend/` (fora de
  `public/`, para não ser servido com cache longo). Os dois são gerados no build e ignorados no Git.
- `SpaController` + a rota catch-all (última do `routes.rb`) entregam o `index.html` em qualquer
  navegação que aceite HTML. **Rotas do frontend não podem começar com `/api`, `/up` ou `/assets`.**
- Credenciais só por ambiente (`DATABASE_URL`, `SECRET_KEY_BASE`, vindas do Secret Manager); o
  initializer `require_production_env.rb` aborta se faltarem.
- O serviço roda com **uma instância e um processo** (o `rate_limit` usa cache em memória). Não
  adicione `workers` ao Puma nem aumente `--max-instances` sem trocar o cache por um compartilhado.
- Migrations rodam no `api/bin/docker-entrypoint` antes de o servidor subir.

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

## Autenticação

- Toda ação de controller exige login por padrão (`Authentication` incluído no
  `ApplicationController`). Novos módulos já nascem protegidos; não adicione nada para isso.
- Para liberar uma ação: `allow_unauthenticated_access only: :acao`. Só use com motivo explícito na spec.
- Usuário e sessão da requisição: `Current.user` e `Current.session`.
- Sessão em tabela `sessions`, identificada por token num cookie assinado `HttpOnly`/`SameSite=Lax`.
  Nunca devolva o token no JSON nem guarde credenciais no JavaScript.
- `POST/PUT/PATCH/DELETE` exigem `Content-Type: application/json` (proteção contra CSRF).
- No frontend, use `useAuth()` de `web/src/core/auth-context.ts`. O cliente `core/api.ts` já leva ao
  login quando a API responde 401.
- Testes de request: chame `sign_in_as users(:owner)` no `setup`. O teste
  `test/integration/authentication_required_test.rb` verifica automaticamente que toda rota nova
  de `/api/v1` responde 401 sem login.
- Ainda não há multiusuário: os dados dos módulos não têm `user_id`. Não filtre por usuário até a
  feature de multiusuário.

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
