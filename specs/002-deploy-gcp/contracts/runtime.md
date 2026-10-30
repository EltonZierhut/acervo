# Contrato: execução em produção

## Variáveis de ambiente

| Variável | Obrigatória | Origem no Cloud Run | Uso |
|---|---|---|---|
| `DATABASE_URL` | sim | Secret Manager (`DATABASE_URL`) | conexão direta do Neon, com `sslmode=require` |
| `SECRET_KEY_BASE` | sim | Secret Manager (`SECRET_KEY_BASE`) | assina o cookie de sessão |
| `PORT` | definida pela plataforma | Cloud Run (8080) | porta do Puma |
| `RAILS_ENV` | já definida na imagem | `production` | |
| `RAILS_MAX_THREADS` | não (padrão 3) | — | threads do Puma e tamanho do pool |
| `RAILS_LOG_LEVEL` | não (padrão `info`) | — | |

Sem `DATABASE_URL` ou `SECRET_KEY_BASE`, o processo termina na inicialização com:
`Variáveis de ambiente obrigatórias ausentes em produção: <lista>`.

## Inicialização do container

1. `bin/docker-entrypoint` → `bin/rails db:migrate` (falha → processo termina com erro).
2. `exec bin/rails server` (Puma em `0.0.0.0:$PORT`).

## Roteamento HTTP

| Requisição | Resposta |
|---|---|
| `GET /up` | 200 (sem login, sem redirecionar para HTTPS) |
| `GET /assets/<arquivo-com-hash>` existente | arquivo, `Cache-Control: public, max-age=31536000, immutable` |
| `GET /assets/...` inexistente | 404 |
| `/api/...` | API (contratos em `specs/001-email-password-auth/contracts/`); rota inexistente → 404 |
| `GET /` ou qualquer outro caminho, aceitando HTML | `index.html` da interface, `Cache-Control: no-cache` |
| Qualquer requisição HTTP (não HTTPS) | redirecionada para HTTPS pelo próprio Cloud Run; o Rails envia HSTS (`Strict-Transport-Security`) nas respostas |

## Comando de publicação

`bin/deploy-gcp` (raiz do repositório). Variáveis opcionais: `GCP_PROJECT` (padrão: projeto
configurado no `gcloud`), `SERVICE` (padrão `acervo`), `REGION` (padrão `southamerica-east1`).

Parâmetros fixos: `--source .`, `--allow-unauthenticated`, `--port 8080`, `--memory 512Mi`,
`--cpu 1`, `--min-instances 0`, `--max-instances 1`,
`--set-secrets DATABASE_URL=DATABASE_URL:latest,SECRET_KEY_BASE=SECRET_KEY_BASE:latest`.
