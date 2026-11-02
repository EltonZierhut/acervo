# Imagem do agente: um container descartável por execução, sem credenciais do GitHub.
# O executor monta o clone em /workspace e roda com o usuário da máquina (--user).
#
# Traz o necessário para rodar os testes do próprio Acervo (e de projetos parecidos): Ruby 3.3, Node 22 e
# PostgreSQL 16, que o entrypoint liga em localhost:5432 (usuário postgres, sem senha) antes do Claude Code.
FROM node:22-bookworm-slim AS node

FROM ruby:3.3.6-bookworm

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# PostgreSQL 16 do repositório oficial (mesma versão do CI e do docker-compose, para o pg_dump gerar a
# structure.sql igual). O nss_wrapper dá nome ao usuário do --user, que não existe no /etc/passwd e sem o
# qual o initdb não roda.
RUN install -d /usr/share/postgresql-common/pgdg \
  && curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ripgrep python3 libnss-wrapper postgresql-16 postgresql-client-16 \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@2.1.316

# O /home/agent é um tmpfs sem permissão de execução, então as gems ficam na imagem; o bundle install da
# execução escreve aqui, com o usuário da máquina.
RUN chmod -R a+rwX /usr/local/bundle

COPY agent-entrypoint.sh /usr/local/bin/agent-entrypoint
RUN chmod 755 /usr/local/bin/agent-entrypoint

ENV GIT_OPTIONAL_LOCKS=0 \
    DISABLE_AUTOUPDATER=1 \
    HOME=/home/agent \
    PATH=/usr/lib/postgresql/16/bin:$PATH
RUN mkdir -p /home/agent && chmod 777 /home/agent
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/agent-entrypoint"]
