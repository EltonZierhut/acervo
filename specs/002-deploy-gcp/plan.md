# Plano de implementação: Preparar o Acervo para o Google Cloud

**Branch**: `002-deploy-gcp` | **Data**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação da feature em `specs/002-deploy-gcp/spec.md`

## Resumo

Empacotar API e interface numa única imagem de container (Dockerfile multi-stage na raiz), com
o Rails servindo o build do React e um *fallback* de rotas da SPA. Configurar produção para o
Cloud Run (HTTPS terminado pela plataforma, porta `$PORT`, credenciais do Secret Manager,
migrations ao iniciar) e entregar um comando de publicação (`bin/deploy-gcp`) e um guia em
português (`docs/deploy-gcp.md`) para o dono criar as contas (Google Cloud + Neon em São Paulo)
e publicar. Decisões em [research.md](research.md).

## Contexto técnico

**Linguagem/versão**: Ruby 3.3 / Rails 8.0; Node 22 / React 19 (apenas no build)

**Dependências principais**: nenhuma gem ou pacote novo. Imagens base `ruby:3.3-slim` e
`node:22-slim`; `libpq5` na imagem final; ferramentas externas `gcloud` e Docker (opcional
localmente)

**Armazenamento**: PostgreSQL gerenciado no Neon (`aws-sa-east-1`), conexão direta com SSL

**Testes**: Minitest (request tests do `SpaController`); `npm run build` e `npm run lint`

**Plataforma**: Google Cloud Run, região `southamerica-east1`, 1 instância, 512 MiB, escala a zero

**Tipo de projeto**: aplicação web (API Rails + SPA React) publicada como um serviço

**Metas de desempenho**: primeira requisição após inatividade em poucos segundos (início do
container + Neon acordando); requisições seguintes sem diferença perceptível do desenvolvimento

**Restrições**: uma instância e um processo (limite de tentativas em memória); sem credenciais no
repositório nem na imagem; custo dentro das cotas gratuitas para uso pessoal

**Escala/escopo**: 1 usuário; 1 serviço; 2 segredos

## Verificação da constituição

*GATE: deve passar antes da Fase 0 e ser reavaliado depois da Fase 1.*

| Princípio | Avaliação | Status |
|---|---|---|
| I. Modularidade | Mudanças só no núcleo (`SpaController`, rotas, configuração, infraestrutura). Nenhum módulo é alterado; módulos novos são servidos pelo mesmo fallback sem configuração extra. | ✅ |
| II. Simplicidade | Um serviço, uma imagem, nenhuma dependência de código nova. Migrations no entrypoint em vez de um Cloud Run Job. Sem CI, CDN ou domínio nesta feature. | ✅ |
| III. Busca | Não se aplica. | ✅ n/a |
| IV. Contrato de API | Nenhuma rota da API muda. O fallback da SPA exclui explicitamente `/api`, garantindo 404 em rotas de API inexistentes. | ✅ |
| V. Qualidade | Request tests do fallback (HTML, exclusões, 404, cache). Testes existentes devem continuar verdes. Migrations inalteradas. | ✅ |
| VI. Idioma | Guia, mensagens e commits em português; código em inglês. | ✅ |

**Resultado (antes da pesquisa)**: aprovado. **Reavaliação após o design**: aprovado.

## Estrutura do projeto

### Documentação (desta feature)

```text
specs/002-deploy-gcp/
├── spec.md
├── plan.md
├── research.md
├── data-model.md        # sem entidades novas
├── quickstart.md
├── contracts/runtime.md # variáveis, inicialização, roteamento, comando de publicação
├── checklists/requirements.md
└── tasks.md
```

### Código-fonte (arquivos novos ou alterados)

```text
Dockerfile                                   # multi-stage: web build → gems → imagem final
.dockerignore
.gitignore                                   # + api/frontend/, api/public/assets/
bin/deploy-gcp                               # gcloud run deploy com os parâmetros fixos
docs/deploy-gcp.md                           # guia de publicação para o dono
README.md                                    # seção "Publicação" apontando para o guia
CLAUDE.md                                    # comandos de deploy e convenção da SPA

api/
├── bin/docker-entrypoint                    # db:migrate e exec do servidor
├── public/.keep
├── app/controllers/spa_controller.rb        # entrega frontend/index.html (fora de public/)
├── config/
│   ├── routes.rb                            # root + catch-all da SPA (por último)
│   ├── database.yml                         # produção só com DATABASE_URL
│   ├── environments/production.rb           # assume_ssl, force_ssl, arquivos estáticos
│   └── initializers/require_production_env.rb
└── test/controllers/spa_controller_test.rb
```

**Decisão de estrutura**: o `Dockerfile` fica na raiz porque precisa de `api/` e `web/`, e
porque `gcloud run deploy --source .` o encontra automaticamente.

## Acompanhamento de complexidade

Nenhuma violação da constituição a justificar.
