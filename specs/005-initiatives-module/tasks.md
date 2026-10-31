# Tarefas: Módulo Iniciativas (fase 1)

**Entrada**: `specs/005-initiatives-module/` (spec, plano, pesquisa, modelo de dados, contrato e guia de validação)

**Testes**: incluídos porque o princípio V da constituição exige testes de models e request tests.

**Formato**: `[P]` pode rodar em paralelo; `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Criar a branch `005-initiatives-module` a partir da `main` atualizada

## Fase 2: Base (bloqueia todas as histórias)

- [X] T002 Criar api/db/migrate/20261031000001_create_initiatives_module.rb com as quatro tabelas, `CHECK`s, colunas geradas e índices de data-model.md, reversível por `change`
- [ ] T003 Rodar `db:migrate` e `db:migrate:redo` e atualizar api/db/structure.sql (structure.sql gerado a partir do SQL equivalente num PostgreSQL 16; falta rodar no Rails)
- [X] T004 [P] Criar api/app/models/initiatives.rb com `table_name_prefix`
- [X] T005 [P] Registrar o módulo em api/config/modules.yml e o `namespace :initiatives` em api/config/routes.rb (rotas aninhadas `shallow`)
- [X] T006 [P] Criar web/src/modules/initiatives/{types.ts,api.ts,labels.ts} conforme contracts/initiatives-api.md
- [X] T007 Criar web/src/modules/initiatives/index.tsx e registrar em web/src/modules/index.ts

## Fase 3: História 1 - Cadastrar e encontrar iniciativas (P1)

**Objetivo**: criar iniciativas e encontrá-las por busca e filtros.

**Teste independente**: criar duas iniciativas e achar uma por trecho do nome e por status.

- [X] T008 [P] [US1] Testes do model em api/test/models/initiatives/initiative_test.rb: nome obrigatório, padrões, status/prioridade/seções válidos, datas, tags, ordem, progresso
- [X] T009 [P] [US1] Request tests de iniciativas em api/test/integration/initiatives_api_test.rb
- [X] T010 [US1] Criar api/app/models/initiatives/initiative.rb
- [X] T011 [US1] Criar api/app/controllers/api/v1/initiatives/initiatives_controller.rb
- [X] T012 [P] [US1] Criar web/src/modules/initiatives/components/{ProgressBar,ContextBadge,InitiativeForm}.tsx
- [X] T013 [US1] Criar web/src/modules/initiatives/pages/InitiativesPage.tsx (busca com debounce, filtros na URL, paginação) e pages/NewInitiativePage.tsx
- [X] T014 [US1] Criar web/src/modules/initiatives/pages/InitiativePage.tsx com cabeçalho, abas pela URL (`?aba=`), aba Detalhes, apagar e "não encontrada"

## Fase 4: História 2 - Tarefas (P1)

**Objetivo**: anotar, concluir e acompanhar tarefas de uma iniciativa.

**Teste independente**: criar três tarefas só com título, concluir uma e ver 1/3.

- [X] T015 [P] [US2] Testes do model em api/test/models/initiatives/task_test.rb: título, status, `completed_at`, marco da mesma iniciativa, ordem, atraso, `touch`
- [X] T016 [P] [US2] Request tests de tarefas em api/test/integration/initiatives_api_test.rb
- [X] T017 [US2] Criar api/app/models/initiatives/task.rb
- [X] T018 [US2] Criar api/app/controllers/api/v1/initiatives/tasks_controller.rb
- [X] T019 [US2] Criar web/src/modules/initiatives/components/{TaskList,TaskItem}.tsx: criação rápida com Enter, grupos por status, concluir com um clique, edição em linha, busca e filtro, atraso destacado

## Fase 5: História 3 - Marcos (P2)

**Objetivo**: acompanhar entregas e o progresso de cada uma.

**Teste independente**: marco com duas tarefas, uma concluída, mostra 1/2.

- [X] T020 [P] [US3] Testes do model em api/test/models/initiatives/milestone_test.rb: título, `completed`, ordem, progresso, apagar mantém tarefas
- [X] T021 [P] [US3] Request tests de marcos em api/test/integration/initiatives_api_test.rb
- [X] T022 [US3] Criar api/app/models/initiatives/milestone.rb
- [X] T023 [US3] Criar api/app/controllers/api/v1/initiatives/milestones_controller.rb
- [X] T024 [US3] Criar web/src/modules/initiatives/components/MilestoneList.tsx e o seletor de marco na edição de tarefa

## Fase 6: História 4 - Contextos e seções (P2)

**Objetivo**: separar iniciativas por área e escolher as abas de cada uma.

**Teste independente**: filtrar por contexto; desligar Marcos e ver a aba sumir.

- [X] T025 [P] [US4] Testes do model em api/test/models/initiatives/context_test.rb: nome único sem maiúsculas, cor, apagar mantém iniciativas
- [X] T026 [P] [US4] Request tests de contextos em api/test/integration/initiatives_api_test.rb
- [X] T027 [US4] Criar api/app/models/initiatives/context.rb
- [X] T028 [US4] Criar api/app/controllers/api/v1/initiatives/contexts_controller.rb
- [X] T029 [US4] Criar web/src/modules/initiatives/pages/ContextsPage.tsx; seções e contexto no InitiativeForm; abas conforme `sections`

## Fase 7: Acabamento

- [X] T030 [P] Estilos do módulo em web/src/index.css (claro e escuro, telas estreitas)
- [X] T031 [P] Exemplos em api/db/seeds.rb
- [X] T032 [P] Atualizar CLAUDE.md e README.md (a constituição não muda: segue correta)
- [ ] T033 Rodar `bin/rails test`, `db:migrate:redo`, `npm run build`, `npm run lint` e o roteiro de quickstart.md (build, lint e telas verificados; testes do Rails pendentes)

## Dependências

- Fase 2 bloqueia as histórias. US1 vem antes de US2 e US3 (página da iniciativa).
- US3 depende de US2 para o progresso dos marcos; US4 pode correr em paralelo a US2/US3.
