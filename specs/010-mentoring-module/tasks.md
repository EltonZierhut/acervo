# Tarefas: Módulo Mentoria (fase 1)

**Entrada**: `specs/010-mentoring-module/` (spec, plano, pesquisa, modelo de dados e contrato)

**Testes**: incluídos porque o princípio V da constituição exige testes de models e request tests.

**Formato**: `[P]` pode rodar em paralelo; `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Criar a branch `010-mentoring-module` a partir da `main` atualizada

## Fase 2: Base (bloqueia todas as histórias)

- [X] T002 Criar api/db/migrate/20261111000001_create_mentoring_module.rb com as sete tabelas, `CHECK`s, colunas geradas e índices de data-model.md, reversível por `change`
- [X] T003 Atualizar api/db/structure.sql (SQL equivalente aplicado num PostgreSQL 16 e conferido com `pg_dump`; `db:schema:load` roda no CI)
- [X] T004 [P] Criar api/app/models/mentoring.rb com `table_name_prefix`
- [X] T005 [P] Registrar o módulo em api/config/modules.yml e o `namespace :mentoring` em api/config/routes.rb
- [X] T006 [P] Criar web/src/modules/mentoring/{types.ts,api.ts,labels.ts} conforme contracts/mentoring-api.md
- [X] T007 Criar web/src/modules/mentoring/index.tsx, o ícone em core/icons.tsx e registrar em web/src/modules/index.ts

## Fase 3: História 1 - Mentoria e questionário (P1)

- [X] T008 [P] [US1] Testes em api/test/models/mentoring/mentorship_test.rb e question_test.rb: validações, perguntas sugeridas, posição, mover
- [X] T009 [US1] Criar api/app/models/mentoring/{mentorship,question,suggested_questions}.rb
- [X] T010 [US1] Criar controllers de mentorias e perguntas e serialization.rb
- [X] T011 [US1] Criar pages/{MentorshipsPage,NewMentorshipPage,MentorshipPage}.tsx, components/{MentorshipForm,Markdown,MarkdownField}.tsx e tabs/QuestionsTab.tsx (com "Copiar questionário")

## Fase 4: História 2 - Objetivos (P1)

- [X] T012 [P] [US2] Testes em api/test/models/mentoring/goal_test.rb: progresso, situação, atraso
- [X] T013 [US2] Criar model e controller de objetivos e tabs/GoalsTab.tsx

## Fase 5: História 3 - Encontros e ações (P1)

- [X] T014 [P] [US3] Testes em api/test/models/mentoring/{meeting,action_item}_test.rb: busca, vínculos da mesma mentoria, conclusão, ordem
- [X] T015 [US3] Criar models e controllers de encontros e ações
- [X] T016 [US3] Criar pages/MeetingPage.tsx, components/ActionItemList.tsx, tabs/{MeetingsTab,ActionItemsTab}.tsx

## Fase 6: História 4 - Autoavaliação (P2)

- [X] T017 [P] [US4] Testes em api/test/models/mentoring/assessments_test.rb: substituição na mesma data, primeira/última/variação, nota nula apaga
- [X] T018 [US4] Criar models competency e rating, o serviço assessments.rb, controllers de competências e autoavaliações
- [X] T019 [US4] Criar components/ScorePicker.tsx e tabs/AssessmentTab.tsx

## Fase 7: História 5 - Painel (P2)

- [X] T020 [P] [US5] Testes em api/test/models/mentoring/overview_test.rb, indicador por indicador, e mentoria vazia
- [X] T021 [US5] Criar api/app/models/mentoring/overview.rb, a rota `overview` e o resumo da lista de mentorias
- [X] T022 [US5] Criar tabs/OverviewTab.tsx

## Fase 8: Acabamento

- [X] T023 Request tests em api/test/integration/mentoring_api_test.rb
- [X] T024 Rotas novas em web/e2e/responsive.spec.ts e respostas simuladas em e2e/mock-api.ts
- [X] T025 `npm run build`, `npm run lint` e `npm run test:e2e` nas rotas novas (360 px e tela larga, claro e escuro; as 4 falhas restantes do e2e já existiam na `main`, em Iniciativas e Códigos)
- [ ] T026 `bin/rails test` (no CI do PR)
- [X] T027 Atualizar a lista de módulos no CLAUDE.md (a constituição só cita o primeiro módulo; sem alteração)
- [ ] T028 Conferir no app instalado e no celular (roteiro de specs/008-pwa-installable/quickstart.md)
