# Tarefas: Módulo Flashcards (fase 1)

**Entrada**: `specs/009-flashcards-module/` (spec, plano, pesquisa, modelo de dados e contrato)

**Testes**: incluídos porque o princípio V da constituição exige testes de models e request tests.

**Formato**: `[P]` pode rodar em paralelo; `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Criar a branch `009-flashcards-module` a partir da `main` atualizada

## Fase 2: Base (bloqueia todas as histórias)

- [X] T002 Criar api/db/migrate/20261107000001_create_flashcards_module.rb com as quatro tabelas, `CHECK`s, colunas geradas e índices de data-model.md, reversível por `change`
- [ ] T003 Rodar `db:migrate` e `db:migrate:redo` no Rails (structure.sql gerado a partir do SQL equivalente num PostgreSQL 16 e conferido com `db:schema:load` no CI)
- [X] T004 [P] Criar api/app/models/flashcards.rb com `table_name_prefix`
- [X] T005 [P] Registrar o módulo em api/config/modules.yml e o `namespace :flashcards` em api/config/routes.rb
- [X] T006 [P] Criar web/src/modules/flashcards/{types.ts,api.ts} conforme contracts/flashcards-api.md
- [X] T007 Criar web/src/modules/flashcards/index.tsx, o ícone em core/icons.tsx e registrar em web/src/modules/index.ts

## Fase 3: História 1 - Baralhos e notas (P1)

- [X] T008 [P] [US1] Testes em api/test/models/flashcards/note_test.rb: validações, cartões por tipo, troca de tipo, recomeçar, busca, cascata
- [X] T009 [US1] Criar api/app/models/flashcards/{deck,note,card}.rb
- [X] T010 [US1] Criar api/app/controllers/api/v1/flashcards/{decks,notes}_controller.rb e serialization.rb
- [X] T011 [US1] Criar web/src/modules/flashcards/pages/{DecksPage,DeckPage,NotePage}.tsx e components/{NoteForm,DueCounts,Markdown}.tsx

## Fase 4: História 2 - Estudo (P1)

- [X] T012 [P] [US2] Testes do agendador em api/test/models/flashcards/scheduler_test.rb, regra por regra de research.md
- [X] T013 [P] [US2] Testes da fila em api/test/models/flashcards/study_queue_test.rb: ordem, limites diários, virada às 4h, suspensas
- [X] T014 [US2] Criar api/app/models/flashcards/{scheduler,study_day,study_queue,review}.rb
- [X] T015 [US2] Criar api/app/controllers/api/v1/flashcards/study_controller.rb (`GET /decks/:deck_id/study`, `POST /cards/:id/review`)
- [X] T016 [US2] Criar web/src/modules/flashcards/pages/StudyPage.tsx com atalhos de teclado e recarga automática quando um cartão em aprendizado vence

## Fase 5: História 3 - Encontrar e manter notas (P2)

- [X] T017 [US3] Busca paginada, suspender e recomeçar na API e nas telas
- [X] T018 Request tests em api/test/integration/flashcards_api_test.rb

## Fase 6: Acabamento

- [X] T019 Rotas novas em web/e2e/responsive.spec.ts e respostas simuladas em e2e/mock-api.ts
- [X] T020 `npm run build`, `npm run lint` e `npm run test:e2e` nas rotas novas (360 px e tela larga, claro e escuro)
- [X] T021 `bin/rails test` (passou no CI do PR #23)
- [ ] T022 Conferir no app instalado e no celular (roteiro de specs/008-pwa-installable/quickstart.md)
