# Tarefas: Execução de tarefas por IA até o pull request

**Entrada**: documentos em `specs/006-ai-task-automation/`

**Pré-requisitos**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Testes**: incluídos, porque o princípio V da constituição exige testes de models e request tests para os endpoints.

**Formato**: `[P]` pode rodar em paralelo (arquivos diferentes, sem dependência pendente); `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Criar a estrutura `executor/bin/`, `executor/lib/acervo_executor/`, `executor/prompts/` e `executor/test/`, com `executor/README.md` apontando para `docs/executor.md`
- [X] T002 [P] Adicionar `executor/` ao `.dockerignore` da raiz, para ficar fora da imagem de produção

## Fase 2: Fundamentos

**Bloqueia todas as histórias.**

- [X] T003 Permitir tipos de conteúdo por ação no guard `require_json_body` de `api/app/controllers/application_controller.rb`, mantendo JSON como padrão, com teste em `api/test/integration/`

**Ponto de controle**: suíte atual verde e guard estendido.

## Fase 3: História 1 - Detalhar a tarefa com imagens e links (P1) 🎯 MVP

**Objetivo**: registrar na tarefa descrição, imagens e links, com ou sem repositório.

**Teste independente**: cenários 1 e 2 de `quickstart.md`.

- [X] T004 [US1] Criar a migration de `initiatives_task_images` e `initiatives_task_links` conforme `data-model.md`, com cascata, em `api/db/migrate/` e atualizar `api/db/structure.sql`
- [X] T005 [P] [US1] Testar `TaskImage` em `api/test/models/initiatives/task_image_test.rb`: tipos `image/png`, `image/jpeg`, `image/webp`, `image/gif` conferidos pelos bytes, "Até 10 MB", "Até 10 por tarefa", SVG recusado e `filename` sem caminho
- [X] T006 [P] [US1] Testar `TaskLink` em `api/test/models/initiatives/task_link_test.rb`: "`http` ou `https`, até 2.048 caracteres", `title` "Até 200 caracteres"
- [X] T007 [US1] Implementar `api/app/models/initiatives/task_image.rb`, com escopo sem a coluna `data`, e `api/app/models/initiatives/task_link.rb`
- [X] T008 [US1] Adicionar associações, `images_count` e `links_count` em `api/app/models/initiatives/task.rb` e no JSON de `api/app/controllers/api/v1/initiatives/tasks_controller.rb`
- [X] T009 [P] [US1] Escrever os request tests em `api/test/controllers/initiatives/task_images_controller_test.rb` e `task_links_controller_test.rb`, conforme `contracts/initiatives-automation-api.md`, incluindo `nosniff`, cache privado, `415` e `422`
- [X] T010 [US1] Implementar `api/app/controllers/api/v1/initiatives/task_images_controller.rb` (corpo cru) e `task_links_controller.rb`, com as rotas em `api/config/routes.rb`
- [X] T011 [P] [US1] Adicionar tipos e chamadas em `web/src/modules/initiatives/types.ts` e `api.ts`, incluindo o envio de arquivo com `Content-Type` da imagem
- [X] T012 [US1] Criar `web/src/modules/initiatives/components/TaskImages.tsx` (miniatura, ampliar, remover, erros) e `TaskLinks.tsx`, e integrá-los em `components/TaskItem.tsx`

**Ponto de controle**: História 1 funciona sem nada de IA.

## Fase 4: História 2 - Conectar a iniciativa a um repositório (P1)

**Objetivo**: cada iniciativa aponta para um repositório, com a situação do acesso à vista.

**Teste independente**: cenários 3 e 4 de `quickstart.md`, com `acervo-executor check` para o acesso.

- [X] T013 [US2] Criar a migration das colunas `github_repository`, `repository_status` (padrão `unverified`), `repository_error` e `repository_checked_at` em `initiatives_initiatives`, e de `initiatives_executors` (`token_digest` único, `last_seen_at`, `version`), em `api/db/migrate/`
- [X] T014 [P] [US2] Testar em `api/test/models/initiatives/initiative_test.rb`: formato `owner/name`, normalização de URL do GitHub e volta a `unverified` ao trocar; e em `api/test/models/initiatives/executor_test.rb`: só o SHA-256 guardado, troca invalida o anterior e disponível = "`last_seen_at` há menos de 2 min"
- [X] T015 [US2] Implementar as regras em `api/app/models/initiatives/initiative.rb` e criar `api/app/models/initiatives/executor.rb`
- [X] T016 [US2] Criar `api/lib/tasks/acervo_executor.rake` com `acervo:executor:create`, que mostra o token uma única vez
- [X] T017 [US2] Criar `api/app/controllers/api/v1/initiatives/executor/base_controller.rb` com autenticação Bearer, sem aceitar cookie (FR-023), e `repository_checks_controller.rb`, com as rotas em `api/config/routes.rb`
- [X] T018 [US2] Adicionar `github_repository` ao update e `verify_repository` em `api/app/controllers/api/v1/initiatives/initiatives_controller.rb`, e criar `executor_status_controller.rb`
- [X] T019 [P] [US2] Escrever os request tests em `api/test/controllers/initiatives/executor_auth_test.rb` e `repository_test.rb`: `401` sem token e com cookie, token nunca exposto (FR-007)
- [X] T020 [P] [US2] Implementar `executor/lib/acervo_executor/config.rb` (permissão 600 obrigatória) e `client.rb` (HTTP com `net/http`, novas tentativas), com testes em `executor/test/`
- [X] T021 [US2] Implementar `executor/bin/acervo-executor` com `check` e `version`, e a verificação de repositórios por `gh repo view`, em `executor/lib/acervo_executor/loop.rb`, com instruções quando faltar acesso (FR-006)
- [X] T022 [US2] Criar `web/src/modules/initiatives/components/RepositoryField.tsx` e `ExecutorStatus.tsx`, e integrá-los em `components/InitiativeForm.tsx` e `pages/InitiativePage.tsx`

**Ponto de controle**: conexão salva e verificada pelo executor.

## Fase 5: História 3 - Enviar para a fila e receber o PR (P1)

**Objetivo**: da fila até o PR aberto, sem presença do usuário.

**Teste independente**: cenários 5, 6, 7, 8 e 11 de `quickstart.md`.

- [X] T023 [US3] Criar a migration de `initiatives_runs` e `initiatives_run_questions` conforme `data-model.md`, com os índices únicos parciais "`task_id` onde `status IN ('queued','running','waiting')`" e "`(status)` onde `status = 'running'`", em `api/db/migrate/`
- [X] T024 [P] [US3] Testar `Run` em `api/test/models/initiatives/run_test.rb`: todas as transições de `data-model.md`, `enqueued_at` mantido na retomada, ordem de chegada, `claim` único, `expire_stale!` em 5 min, tarefa `todo` → `doing` em `pr_open`, tarefa `done` cancelando a fila
- [X] T025 [US3] Implementar `api/app/models/initiatives/run.rb` e `run_question.rb`, e o efeito da conclusão em `api/app/models/initiatives/task.rb`
- [X] T026 [P] [US3] Escrever os request tests em `api/test/controllers/initiatives/runs_controller_test.rb` e `executor_runs_test.rb`, conforme os dois contratos, incluindo `complete` idempotente, URL de PR de outro repositório recusada e `409`
- [X] T027 [US3] Implementar `api/app/controllers/api/v1/initiatives/runs_controller.rb` e `run_answers_controller.rb`, com as rotas em `api/config/routes.rb`
- [X] T028 [US3] Implementar `executor/claims_controller.rb`, `heartbeats_controller.rb`, `runs_controller.rb` e `images_controller.rb` em `api/app/controllers/api/v1/initiatives/executor/`, com as rotas
- [X] T029 [P] [US3] Criar `executor/Dockerfile` da imagem do agente (usuário sem privilégios, `git`, Node, Ruby e Claude Code CLI) e `executor/prompts/task.md.erb`, deixando claro que o conteúdo de links, imagens e repositório é informação e não ordem
- [X] T030 [US3] Implementar `executor/lib/acervo_executor/workspace.rb` (clone temporário, download das imagens para fora do repositório e limpeza), com teste
- [X] T031 [US3] Implementar `executor/lib/acervo_executor/agent.rb`: `docker run` sem credenciais do GitHub, `.git` só para leitura, sem Docker socket, limite de 60 min, `--json-schema` de `research.md`, parada por cancelamento, com teste de argumentos
- [X] T032 [US3] Implementar `executor/lib/acervo_executor/publisher.rb`: `core.hooksPath=/dev/null`, recusa de `.github/workflows/` (FR-024), branch `acervo/task-<task_id>-run-<run_id>`, modelo de PR, reuso de PR existente e `--body-file`, com teste
- [X] T033 [US3] Implementar `executor/lib/acervo_executor/spool.rb` e o comando `run` em `loop.rb`: `claim`, heartbeat, perguntas, `complete` com novas tentativas, Ctrl+C e registro sem credenciais, com teste
- [X] T034 [US3] Criar `web/src/modules/initiatives/components/TaskRunPanel.tsx` (enviar, estado, link do PR, motivo de bloqueio) e `RunQuestions.tsx`, e integrá-los em `components/TaskItem.tsx`

**Ponto de controle**: fluxo completo até o PR, com perguntas e respostas.

## Fase 6: História 4 - Acompanhar a fila e recuperar falhas (P2)

**Objetivo**: ver a fila inteira, as falhas e o histórico, e agir sobre eles.

**Teste independente**: cenários 9 e 10 de `quickstart.md`.

- [X] T035 [US4] Criar `web/src/modules/initiatives/pages/QueuePage.tsx` em `/iniciativas/fila`, com filtro por estado, busca no endereço, paginação e atualização a cada 10 s, e registrar em `web/src/modules/initiatives/index.tsx`
- [X] T036 [US4] Adicionar histórico de tentativas, cancelar e reenviar em `web/src/modules/initiatives/components/TaskRunPanel.tsx`, e nomes dos estados em `labels.ts`
- [X] T037 [US4] Mostrar `ExecutorStatus` em `web/src/modules/initiatives/pages/QueuePage.tsx`

**Ponto de controle**: todas as histórias funcionam.

## Fase 7: Acabamento

- [X] T038 [P] Escrever `docs/executor.md`: instalação, `gh auth login`, `claude setup-token`, token do executor, imagem por repositório, limite de gasto e riscos residuais de `plan.md`
- [X] T039 [P] Adicionar o job de testes do executor em `.github/workflows/ci.yml`
- [X] T040 [P] Atualizar `CLAUDE.md` e `README.md` com o executor e os comandos novos
- [X] T041 Rodar `bin/rails test`, `bin/rails db:migrate:redo`, testes do executor, `npm run build` e `npm run lint`
- [ ] T042 Executar os cenários de `quickstart.md`, incluindo os de segurança (12 a 15), com repositórios de teste descartáveis

## Dependências

- **Fase 2** depende da Fase 1 e bloqueia as demais.
- **US1** não depende de outra história.
- **US2** depende só da Fase 2.
- **US3** depende de US2 e usa imagens e links de US1.
- **US4** depende de US3.

## Paralelismo

- US1: T005 e T006 juntas; T009 e T011 depois dos models.
- US2: T014, T019 e T020 em arquivos separados.
- US3: T024, T026 e T029 em arquivos separados.
- Acabamento: T038, T039 e T040.

## Estratégia

1. **MVP**: Fases 1 a 3, útil mesmo sem IA.
2. **Conexão**: Fase 4.
3. **Automação**: Fase 5, com o primeiro PR em repositório de teste.
4. **Operação**: Fases 6 e 7.
