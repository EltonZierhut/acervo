# Pesquisa (Fase 0): Preparar o Acervo para o Google Cloud

## R1. Imagem única com Dockerfile multi-stage na raiz

- **Decisão**: `Dockerfile` na raiz do repositório com três estágios: (1) `node:22-slim` faz
  `npm ci` e `npm run build` em `web/`; (2) `ruby:3.3-slim` instala as gems (`bundle install`
  sem os grupos de desenvolvimento e teste) e pré-compila o bootsnap; (3) imagem final
  `ruby:3.3-slim` com apenas `libpq5`, o código de `api/` e o build do React copiado para
  `api/public/`. Roda com o usuário `rails` (sem root).
- **Justificativa**: `gcloud run deploy --source .` usa o `Dockerfile` da raiz automaticamente.
  Uma imagem com a API e a interface atende ao FR-001 e evita CORS e dois deploys. A imagem final
  sem compiladores fica menor e com menos superfície de ataque.
- **Alternativas**: buildpacks do Google (menos controle sobre Node e Ruby juntos no monorepo);
  duas imagens separadas (dois serviços e cookies entre domínios).

## R2. Rails servindo a SPA

- **Decisão**:
  - `config.public_file_server.enabled = true` em produção, com
    `Cache-Control: public, max-age=31536000, immutable` (arquivos de `assets/` têm hash no nome).
  - O build do React é dividido: `assets/` vai para `api/public/assets/` e o `index.html` vai
    para `api/frontend/index.html`, **fora** de `public/`. Se ficasse em `public/`, o servidor de
    arquivos estáticos o entregaria em `/` com o cache de um ano dos assets, e novas versões não
    apareceriam.
  - `SpaController < ActionController::API` (fora do `ApplicationController`, portanto sem exigir
    login: a página só contém a interface, sem dados) com a ação `index`, que envia
    `api/frontend/index.html` com `Cache-Control: no-cache`; se o arquivo não existir
    (desenvolvimento), responde 404 com um aviso de que a interface roda pelo Vite.
  - Rotas: `root "spa#index"` e um *catch-all* `get "*path", to: "spa#index"` com restrição: só
    requisições que aceitam HTML e cujo caminho não começa com `/api`, `/up` ou `/assets`.
    Fica por último no `routes.rb`.
- **Justificativa**: atende ao FR-002, ao FR-003 e ao FR-004 sem gems novas. O servidor de
  arquivos estáticos responde antes do roteamento, então os assets nunca chegam ao catch-all.
- **Alternativas**: servir a SPA por um bucket ou CDN (dois domínios, contra o modelo de cookie);
  `rack-static` customizado (mais código sem ganho).

## R3. HTTPS atrás do Cloud Run

- **Decisão**: em produção, `config.assume_ssl = true` (o Cloud Run termina o TLS e repassa HTTP)
  e `config.force_ssl = true` com
  `config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }`. Inclui
  HSTS (padrão do `force_ssl`). O cookie de sessão já usa `secure: Rails.env.production?`.
- **Justificativa**: atende ao FR-006 e ao cenário 3 da história 2. Remove a variável `FORCE_SSL`
  atual, deixando o HTTPS sempre ligado em produção.
- **Importante**: com `assume_ssl`, o Rails considera toda requisição como HTTPS, então quem
  redireciona HTTP → HTTPS é o próprio Cloud Run (o endereço `*.run.app` só atende HTTPS). O
  `force_ssl` continua útil: envia o cabeçalho HSTS e marca os cookies como seguros. Por isso, ao
  rodar a imagem localmente, as requisições HTTP são atendidas normalmente, sem redirecionar.
- **Alternativas**: depender só do redirecionamento do Cloud Run (o `*.run.app` já é HTTPS, mas o
  Rails precisa saber disso para gerar URLs e cookies corretamente).

## R4. Credenciais e banco em produção

- **Decisão**:
  - `database.yml` de produção com somente `adapter`, `encoding`, `pool` e
    `url: <%= ENV.fetch("DATABASE_URL") %>`, sem herdar `host`, `username` e `password` locais.
  - `SECRET_KEY_BASE` lida pelo Rails a partir do ambiente; o Rails já recusa iniciar em
    produção sem ela.
  - Initializer `config/initializers/require_production_env.rb` que, em produção, verifica
    `DATABASE_URL` e `SECRET_KEY_BASE` e aborta com mensagem em português (FR-005).
  - No Cloud Run, os dois valores vêm do **Secret Manager** (`--set-secrets`).
  - Neon: usar a connection string **direta** (sem `-pooler`), com `sslmode=require`. Uma
    instância com 3 threads abre no máximo 3 conexões, muito abaixo do limite.
- **Justificativa**: FR-005 e FR-010; o Secret Manager evita credenciais em variáveis visíveis no
  console e no histórico de deploy. A conexão direta evita problemas de *prepared statements* com
  o pooler em modo transação e serve também para as migrations.
- **Alternativas**: variáveis de ambiente comuns no Cloud Run (aparecem no console); pooler do Neon
  (desnecessário com 1 instância).

## R5. Migrations ao iniciar

- **Decisão**: `bin/docker-entrypoint` executa `bin/rails db:migrate` quando o comando é o
  servidor e só então faz `exec` do Puma. `set -e` garante que uma falha impede o servidor de
  subir (FR-008). Em produção `dump_schema_after_migration = false`, então não é preciso
  `pg_dump` na imagem.
- **Justificativa**: com uma instância (`--max-instances 1`), não há corrida entre instâncias
  rodando migrations. É o padrão das imagens geradas pelo Rails 8.
- **Alternativas**: Cloud Run Job separado para migrations (mais um recurso para gerenciar; vale a
  pena só com várias instâncias).
- **Observação**: `db:prepare` foi evitado porque, num banco vazio, tentaria carregar
  `db/structure.sql`, que exigiria o cliente `psql` na imagem e o arquivo versionado. Com
  `db:migrate` o banco é criado do zero pelas migrations, que são a fonte da verdade.

## R6. Porta, processos e memória

- **Decisão**: o Puma já lê `PORT` (o Cloud Run define 8080) e escuta em `0.0.0.0`. Um processo
  (sem `workers`) com `RAILS_MAX_THREADS=3`. Serviço com `--memory 512Mi`, `--cpu 1`,
  `--max-instances 1`, `--min-instances 0` (escala a zero, sem cobrança parada) e cobrança por
  requisição (padrão).
- **Justificativa**: FR-007 e FR-011; o cache em memória do limite de tentativas exige um único
  processo numa única instância. 512 MiB comportam o Rails em modo API com folga.
- **Alternativas**: `min-instances 1` (elimina a demora inicial, mas consome a cota gratuita em
  poucos dias, como mostra a página de preços do Cloud Run).

## R7. Arquivos ignorados e o `Gemfile.lock`

- **Decisão**: `.dockerignore` na raiz excluindo `.git`, `node_modules`, `dist`, `api/log`,
  `api/tmp`, `.env*`, `api/config/master.key`, `specs/` e `.claude/`. `.gitignore` passa a
  ignorar `api/public/index.html` e `api/public/assets/` (gerados no build).
- **Justificativa**: FR-010; imagens menores e sem segredos.
- **Ponto de atenção**: o repositório ainda não tem `api/Gemfile.lock`, porque o projeto nunca
  rodou `bundle install`. O build funciona sem ele, mas as versões ficam sem trava. O guia instrui
  a gerar e versionar o lock (com `bundle lock --add-platform x86_64-linux` se o computador do
  dono não for Linux x86) antes do primeiro deploy.

## R8. Comando de publicação

- **Decisão**: script `bin/deploy-gcp` na raiz (bash) que executa `gcloud run deploy` com os
  parâmetros de R6, `--region southamerica-east1`, `--allow-unauthenticated`, `--port 8080` e
  `--set-secrets DATABASE_URL=DATABASE_URL:latest,SECRET_KEY_BASE=SECRET_KEY_BASE:latest`. Aceita
  `GCP_PROJECT` e `SERVICE` como variáveis opcionais.
- **Justificativa**: FR-011 e SC-002 (um comando); os parâmetros que garantem uma instância e o
  uso de segredos ficam versionados, sem depender da memória do dono.
- **Alternativas**: `cloudbuild.yaml` (útil quando houver CI; fora do escopo).
