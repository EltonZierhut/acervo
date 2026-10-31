# syntax=docker/dockerfile:1
# Imagem de produção do Acervo: API Rails + interface React num único serviço.
# Construída pelo Cloud Run com `bin/deploy-gcp` (ou localmente: docker build -t acervo .).

ARG RUBY_VERSION=3.3.6
ARG NODE_VERSION=22

# ---------- 1. Interface (React + Vite) ----------
FROM node:${NODE_VERSION}-slim AS web
WORKDIR /web
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

# ---------- Base Ruby comum ----------
FROM ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails
ENV RAILS_ENV=production \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test
# postgresql-client: com o banco vazio, o db:migrate carrega db/structure.sql usando o psql.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 curl postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ---------- 2. Gems ----------
FROM base AS gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*
# O Gemfile.lock é opcional aqui, mas deve ser versionado (veja docs/deploy-gcp.md).
COPY api/Gemfile api/Gemfile.lock* ./
RUN if [ -f Gemfile.lock ]; then bundle config set deployment true; fi && \
    bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# ---------- 3. Imagem final ----------
FROM base
COPY --from=gems "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY api/ ./

# assets/ vai para public/ (servido com cache longo); index.html vai para frontend/,
# fora de public/, e é entregue sem cache pelo SpaController.
COPY --from=web /web/dist/ ./public/
RUN mkdir -p frontend && mv public/index.html frontend/index.html && \
    bundle exec bootsnap precompile app/ lib/

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp && chown -R rails:rails log tmp
USER 1000:1000

EXPOSE 8080
ENV PORT=8080
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
