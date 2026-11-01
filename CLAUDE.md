# Acervo

Organizador pessoal modular. Backend Rails 8 API + PostgreSQL em `api/`, frontend React +
TypeScript (Vite) em `web/`. Módulos: **Códigos** (notas e scripts para colar, com busca e salvamento automático) e
**Iniciativas** (projetos de qualquer tipo, com contextos, marcos e tarefas; spec 005). As tarefas podem ser
desenvolvidas por IA até o PR, por um programa executor em `executor/`, na máquina do usuário (spec 006).

Princípios do projeto: `.specify/memory/constitution.md`. Leia antes de planejar ou implementar.

## Idioma

- Responda, escreva specs, documentação, mensagens da interface e commits em **português do Brasil**.
- Código (classes, métodos, variáveis, tabelas, rotas da API) em **inglês**.

## Comandos

```bash
# Docker (desenvolvimento)
docker compose up -d                 # tudo: PostgreSQL + Rails e Vite em um container (:3000 e :5173)
docker compose up -d db              # só o PostgreSQL (postgres/postgres), para rodar o resto na máquina
docker compose exec dev bin/rails test  # comandos do Rails dentro do container

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

# Executor (executor/; guia: docs/executor.md)
ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require "./#{f}" }'  # testes
bin/acervo-executor check            # confere configuração, Docker, gh e API
bin/acervo-executor run              # processa a fila

# Produção (raiz)
docker build -t acervo .             # imagem única: React compilado + Rails
bin/setup-gcp                        # configura Google Cloud e GitHub (uma vez; guia: docs/deploy-gcp.md)
bin/deploy-gcp                       # publica no Cloud Run à mão (o normal é pelo merge na main)
bin/prod-rails acervo:user:create    # tarefa do Rails no banco de produção (Cloud SQL, pelo proxy)
```

## Produção

- Todo merge na `main` é publicado em produção: `.github/workflows/deploy.yml` roda o CI
  (`ci.yml`, também em cada PR) e depois o `bin/deploy-gcp`. Por isso, migrations precisam funcionar
  com a versão anterior do código enquanto a troca acontece.
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

## Executor

- As rotas de `/api/v1/initiatives/executor` autenticam só por token (`Authorization: Bearer`), não por sessão.
- A IA roda em container sem credenciais do GitHub e com `.git` só para leitura. Commit, push e PR são do executor, com
  hooks desligados. Não passe credenciais do GitHub para o container nem deixe o agente publicar.
- `executor/` usa só a biblioteca padrão do Ruby e fica fora da imagem de produção.

## Branches e pull requests

- **Nunca faça commit nem push direto na `main`**, nem em ajustes pequenos. Toda alteração vai em uma
  branch própria e entra por PR. Antes de commitar, confira a branch atual com `git branch --show-current`.
- Depois do merge de um PR, a branch dele acabou: atualize a `main` e crie outra para a próxima alteração.
- A descrição de todo PR segue `.github/pull_request_template.md`, com as seções **Problema**,
  **Solução** e **Custo**. O `gh pr create --body-file` não aplica o template sozinho: preencha as
  três seções no texto enviado.
- Em **Custo**, informe os tokens usados. Se o valor não estiver disponível, escreva "não medido";
  nunca estime.

## Spec Kit

Fluxo para features novas (skills em `.claude/skills/`):

1. `/speckit-specify <descrição>`: cria a branch e `specs/NNN-nome/spec.md`
2. `/speckit-clarify`: opcional, tira dúvidas antes do plano
3. `/speckit-plan`: `plan.md`, modelo de dados, contratos da API
4. `/speckit-tasks`: `tasks.md`
5. `/speckit-analyze`: opcional, checa consistência entre spec, plano e tarefas
6. `/speckit-implement`: executa as tarefas

Ajustes pequenos podem ser feitos sem spec, mas sempre em branch e por PR. Antes de concluir uma tarefa, rode os
testes, o build e o lint da parte alterada.
