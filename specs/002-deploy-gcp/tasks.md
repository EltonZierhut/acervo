---
description: "Lista de tarefas da feature 002: preparar o Acervo para o Google Cloud"
---

# Tarefas: Preparar o Acervo para o Google Cloud

**Entrada**: documentos de design em `specs/002-deploy-gcp/`

**Pré-requisitos**: plan.md, spec.md, research.md, contracts/runtime.md, quickstart.md

**Testes**: incluídos para o fallback da SPA (princípio V da constituição; SC-004 e SC-006).

## Formato: `[ID] [P?] [História] Descrição`

---

## Fase 1: Setup

- [X] T001 [P] Criar `.dockerignore` na raiz excluindo `.git`, `**/node_modules`, `**/dist`, `api/log/*`, `api/tmp/*`, `api/frontend`, `api/public/assets`, `.env*`, `**/.env*`, `api/config/master.key`, `specs/`, `.claude/`, `.specify/`, `docker-compose.yml`
- [X] T002 [P] Adicionar ao `.gitignore` da raiz: `api/frontend/`, `api/public/assets/` e `.env*`; criar `api/public/.keep`

---

## Fase 2: Fundação

- [X] T003 Alterar `api/config/database.yml`: bloco `production` com apenas `adapter: postgresql`, `encoding: unicode`, `pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>` e `url: <%= ENV["DATABASE_URL"] %>` (sem herdar o `default` com host/usuário/senha locais)
- [X] T004 Criar `api/config/initializers/require_production_env.rb`: em `Rails.env.production?`, abortar (`abort`) com "Variáveis de ambiente obrigatórias ausentes em produção: ..." se `DATABASE_URL` ou `SECRET_KEY_BASE` estiverem vazias, exceto quando `SECRET_KEY_BASE_DUMMY` estiver definida (usada só no build da imagem)

---

## Fase 3: História 1 – Pacote único publicável (P1) 🎯 MVP

**Objetivo**: uma imagem com API + interface; interface servida no endereço raiz e nas rotas de navegação

**Teste independente**: rodar a imagem localmente e abrir `/` e `/codigos/projetos`

### Testes da História 1

- [X] T005 [P] [US1] Criar `api/test/controllers/spa_controller_test.rb`: no `setup`, escrever um `index.html` mínimo em `Rails.root.join("frontend")` (guardando e restaurando o arquivo original no `teardown`, se existir); verificar que `GET /` e `GET /codigos/projetos` com `Accept: text/html` respondem 200 com o HTML, `Content-Type` HTML e `Cache-Control` contendo `no-cache`, sem exigir login; que `GET /api/v1/naoexiste` com `Accept: text/html` responde 404 (não o HTML); que `GET /codigos` com `Accept: application/json` responde 404; e que, sem o `index.html`, `GET /` responde 404 com o aviso de que a interface roda pelo Vite

### Implementação da História 1

- [X] T006 [US1] Criar `api/app/controllers/spa_controller.rb` (`< ActionController::API`, fora do `ApplicationController`, portanto sem login): ação `index` que envia `Rails.root.join("frontend", "index.html")` com `type: "text/html"`, `disposition: "inline"` e `Cache-Control: no-cache`; se o arquivo não existir, responde 404 em texto: "Interface não compilada. Em desenvolvimento, use o Vite (http://localhost:5173)."
- [X] T007 [US1] Alterar `api/config/routes.rb`: `root "spa#index"` e, como **última** rota, `get "*path", to: "spa#index", constraints: ->(req) { req.format.html? && !req.path.start_with?("/api", "/up", "/assets") }, format: false`
- [X] T008 [US1] Criar `Dockerfile` na raiz, multi-stage conforme research R1: estágio `web` (`node:22-slim`, `npm ci`, `npm run build` em `/web`); estágio `gems` (`ruby:3.3-slim` + `build-essential libpq-dev git`, `BUNDLE_WITHOUT=development:test`, `BUNDLE_DEPLOYMENT` só se houver `Gemfile.lock`, `bundle install`, `bootsnap precompile --gemfile`); estágio final (`ruby:3.3-slim` + `libpq5 curl`, `ENV RAILS_ENV=production RAILS_LOG_LEVEL=info BUNDLE_WITHOUT=development:test`, copia gems e `api/`, copia `/web/dist` para `api/public/` e move o `index.html` para `api/frontend/` (fora de `public/`, ver research R2), `bootsnap precompile app/ lib/`, usuário `rails` (uid 1000) dono de `log tmp`, `EXPOSE 8080`, `ENTRYPOINT ["/rails/bin/docker-entrypoint"]`, `CMD ["./bin/rails", "server"]`)
- [X] T009 [US1] Alterar `api/config/environments/production.rb`: `config.public_file_server.enabled = true` e `config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}, immutable" }`

**Checkpoint**: testes T005 verdes; `docker build` gera a imagem (quando houver Docker)

---

## Fase 4: História 2 – Configuração segura de produção (P1)

**Objetivo**: HTTPS, credenciais do ambiente, falha clara sem credenciais

- [X] T010 [US2] Alterar `api/config/environments/production.rb`: remover `config.force_ssl = ENV["FORCE_SSL"] == "true"` e adicionar `config.assume_ssl = true`, `config.force_ssl = true` e `config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }`
- [X] T011 [US2] Conferir que `api/config/puma.rb` usa `ENV.fetch("PORT", 3000)` e não define `workers` (um processo); documentar no comentário que o Cloud Run define `PORT=8080`

---

## Fase 5: História 3 – Migrations ao iniciar (P2)

- [X] T012 [US3] Criar `api/bin/docker-entrypoint` (bash, executável, `set -e`): se o comando for o servidor (`./bin/rails server` ou `bin/rails server`), executar `./bin/rails db:migrate` antes; depois `exec "$@"`

---

## Fase 6: História 4 – Publicação com um comando e guia (P2)

- [X] T013 [P] [US4] Criar `bin/deploy-gcp` na raiz (bash, executável, `set -euo pipefail`) que roda `gcloud run deploy "${SERVICE:-acervo}" --source . --region "${REGION:-southamerica-east1}"` com `--project "$GCP_PROJECT"` quando definida, `--allow-unauthenticated --port 8080 --memory 512Mi --cpu 1 --min-instances 0 --max-instances 1 --set-secrets DATABASE_URL=DATABASE_URL:latest,SECRET_KEY_BASE=SECRET_KEY_BASE:latest`; antes, avisa e aborta se não estiver na raiz do repositório ou se `api/Gemfile.lock` não existir
- [X] T014 [P] [US4] Criar `docs/deploy-gcp.md` (guia em português) cobrindo: pré-requisitos (feature de login concluída, testes verdes, `Gemfile.lock` versionado com `bundle lock --add-platform x86_64-linux`); conta e projeto no Google Cloud; **alerta de orçamento**; instalar `gcloud` e habilitar APIs (`run`, `artifactregistry`, `cloudbuild`, `secretmanager`); Neon na região São Paulo e connection string direta; criar os segredos e dar acesso à conta de serviço do Cloud Run (`roles/secretmanager.secretAccessor`); publicar com `bin/deploy-gcp`; criar a conta de acesso com `DATABASE_URL=... bin/rails acervo:user:create`; atualizar versões; ver logs; custos esperados; problemas comuns
- [X] T015 [P] [US4] Atualizar `README.md` com a seção "Publicação" (resumo e link para `docs/deploy-gcp.md`) e `CLAUDE.md` com os comandos de deploy e a convenção do fallback da SPA (rotas de navegação do frontend não podem começar com `/api`, `/up` ou `/assets`)

---

## Fase 7: Polimento e validação

- [X] T016 Validar: `ruby -c` nos arquivos Ruby, `bash -n` nos scripts, `npm run build` e `npm run lint` em `web/`, e o build da imagem com Docker se disponível; se `bundle install` estiver disponível, `bin/rails test`. Caso contrário, registrar o que precisa ser validado localmente
- [ ] T017 Executar o roteiro de `specs/002-deploy-gcp/quickstart.md` (seções 1 e 2) quando houver Ruby e Docker disponíveis
  - **Pendente**: o ambiente da implementação não tinha RubyGems nem Docker. Validado aqui: sintaxe Ruby e bash, `database.yml` de produção, script de deploy com `gcloud` simulado e build do React. Falta rodar `bin/rails test` e `docker build` localmente.

---

## Dependências e ordem

- Setup e Fundação antes das histórias.
- US1 é o MVP; US2 e US3 dependem de US1 (mesmos arquivos de produção e imagem).
- US4 depende do contrato definido em US1–US3, mas os arquivos podem ser escritos em paralelo.
- T009 e T010 alteram o mesmo arquivo: executar em sequência.

## Estratégia

1. Setup + Fundação → US1 (imagem + SPA) → validar build e testes.
2. US2 (segurança) e US3 (migrations).
3. US4 (comando e guia) → o dono executa a Parte 2 (contas) e a Parte 3 (publicação).
