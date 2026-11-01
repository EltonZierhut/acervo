# Imagem do agente: um container descartável por execução, sem credenciais do GitHub.
# O executor monta o clone em /workspace e roda com o usuário da máquina (--user).
FROM node:22-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git ca-certificates curl ripgrep build-essential ruby ruby-dev python3 \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@2.1.316

ENV GIT_OPTIONAL_LOCKS=0 \
    DISABLE_AUTOUPDATER=1 \
    HOME=/home/agent
RUN mkdir -p /home/agent && chmod 777 /home/agent
WORKDIR /workspace
