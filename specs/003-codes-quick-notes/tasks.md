# Tarefas: Códigos como bloco de notas rápido

**Entrada**: `specs/003-codes-quick-notes/` (spec, plano, pesquisa, modelo de dados, contrato e guia de validação)

**Testes**: incluídos porque o princípio V da constituição exige testes de models e request tests.

**Formato**: `[P]` pode rodar em paralelo; `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Conferir que a API, o frontend e o banco estão de pé e registrar a falha atual do teste de tags em api/test/integration/codes_api_test.rb

## Fase 2: Base (bloqueia todas as histórias)

- [X] T002 Criar a migration em api/db/migrate/ conforme data-model.md: remover `project_id`, apagar `codes_projects`, retirar `NOT NULL` de `title`, adicionar a coluna gerada `tags_text`; `down` preenche títulos vazios com a primeira linha do conteúdo e recria `codes_projects` vazia e `project_id`
- [X] T003 Rodar `db:migrate` e `db:migrate:redo` e atualizar api/db/structure.sql
- [X] T004 Remover api/app/models/codes/project.rb, api/app/controllers/api/v1/codes/projects_controller.rb e api/app/controllers/api/v1/codes/search_controller.rb, e as rotas em api/config/routes.rb
- [X] T005 [P] Corrigir `tags=` em api/app/models/concerns/normalizes_tags.rb: "aceita array ou texto separado por vírgulas"
- [X] T006 [P] Adicionar `content` em api/config/initializers/filter_parameter_logging.rb
- [X] T007 [P] Atualizar api/db/seeds.rb e a descrição em api/config/modules.yml, sem projetos

## Fase 3: História 1 - Colar e guardar (P1)

**Objetivo**: criar uma nota informando só o conteúdo, salva automaticamente.

**Teste independente**: colar um script em nota nova e vê-lo na lista, idêntico ao colado.

- [X] T008 [P] [US1] Escrever testes do model em api/test/models/codes/snippet_test.rb: título opcional, `display_title`, conteúdo preservado, "não vazio nem só com espaços; até 1 MB; sem byte nulo", tags como texto
- [X] T009 [P] [US1] Reescrever api/test/integration/codes_api_test.rb conforme contracts/codes-api.md (criação só com conteúdo, 422, listagem sem `content`, rotas removidas com 404)
- [X] T010 [US1] Ajustar api/app/models/codes/snippet.rb: título "até 200 caracteres; em branco vira `null`", limites de conteúdo, `display_title`, sem `belongs_to :project`
- [X] T011 [US1] Ajustar api/app/controllers/api/v1/codes/snippets_controller.rb: serializadores de lista e detalhe, sem projeto, `PG::ProgramLimitExceeded` vira 422
- [X] T012 [P] [US1] Atualizar web/src/modules/codes/types.ts e web/src/modules/codes/api.ts conforme o contrato, sem projetos
- [X] T013 [US1] Criar web/src/modules/codes/useAutosave.ts: um envio por vez, 800 ms de espera, envio imediato ao colar, nova tentativa a cada 5 s, rascunho em `sessionStorage` durante falhas, sem duplicar criação nem sobrescrever a tela
- [X] T014 [P] [US1] Criar web/src/modules/codes/components/SaveStatus.tsx com "salvando", "salvo" e "não salvo"
- [X] T015 [US1] Criar web/src/modules/codes/components/NoteEditor.tsx: `textarea` monoespaçado com foco, "Mais detalhes" com título, tags, linguagem e descrição, avisos de conteúdo inválido, `useBlocker` e `beforeunload`
- [X] T016 [US1] Criar web/src/modules/codes/pages/NotesPage.tsx e usar a rota única `:id?` em web/src/modules/codes/index.tsx, tratando `novo`; remover as páginas de projetos e de snippets e o SubNav

## Fase 4: História 2 - Encontrar e copiar (P1)

**Objetivo**: buscar, abrir e copiar sem sair da tela.

**Teste independente**: buscar um trecho do meio de um script e colar o conteúdo copiado em outro programa.

- [X] T017 [US2] Testar a busca em api/test/integration/codes_api_test.rb: pedaço de conteúdo, de tag e caracteres como `$(`, `*`, `'` e `--`
- [X] T018 [US2] Incluir `tags_text` e `description` em `searchable_partial_columns` em api/app/models/codes/snippet.rb
- [X] T019 [US2] Criar web/src/modules/codes/components/NoteList.tsx: busca com foco e debounce, paginação, tag como filtro, estado vazio com limpar busca, `display_title` cortado sem quebrar o layout
- [X] T020 [US2] Criar web/src/modules/codes/components/NoteView.tsx e adaptar web/src/modules/codes/components/CodeBlock.tsx: sem realce acima de 100 KB, aviso quando a cópia falhar, "não encontrada" com caminho de volta
- [X] T021 [P] [US2] Adicionar em web/src/index.css os dois painéis, um de cada vez em telas estreitas

## Fase 5: História 3 - Editar e apagar (P2)

**Objetivo**: alterar e remover notas com segurança.

**Teste independente**: editar uma nota e reabri-la; apagar outra e não encontrá-la mais.

- [X] T022 [US3] Testar em api/test/integration/codes_api_test.rb: edição, conteúdo vazio mantendo a versão anterior, `updated_at` sem mudança real, exclusão
- [X] T023 [US3] Ligar "Editar" e "Apagar" em web/src/modules/codes/components/NoteView.tsx, com confirmação na própria página, e atualizar a lista depois de salvar ou apagar em web/src/modules/codes/pages/NotesPage.tsx

## Fase 6: História 4 - Manter o que já existe (P2)

**Objetivo**: os códigos atuais continuam como notas.

**Teste independente**: conferir os códigos do seed depois da migration, inclusive o que tinha projeto.

- [X] T024 [US4] Conferir no banco de desenvolvimento que as notas mantêm título, conteúdo, tags, linguagem e descrição depois de `db:migrate` e de `db:migrate:redo`

## Fase 7: Acabamento

- [X] T025 [P] Atualizar CLAUDE.md e README.md: Códigos sem projetos
- [X] T026 [P] Atualizar a descrição do módulo em .specify/memory/constitution.md (alteração PATCH, com Sync Impact Report)
- [X] T027 Rodar `bin/rails test`, `npm run build` e `npm run lint`
- [X] T028 Validar no navegador os cenários de specs/003-codes-quick-notes/quickstart.md, incluindo logs e desempenho

## Ajuste pós-implementação

- [X] T029 Nota sempre editável: remover modo de leitura, botão "Editar", realce e filtro por tag da interface em web/src/modules/codes/, levando copiar e apagar para web/src/modules/codes/components/NoteEditor.tsx
- [X] T030 Remover a dependência highlight.js de web/package.json e atualizar .specify/memory/constitution.md

## Dependências

- A Fase 2 bloqueia todas as histórias.
- US1 e US2 formam o produto mínimo. US3 depende de NoteView (US2) e do editor (US1). US4 depende só da Fase 2.
- Paralelo: T005, T006 e T007; T008 e T009; T012 e T014; T025 e T026.

## Estratégia

Produto mínimo com as fases 1 a 4; validar; depois US3, US4 e acabamento, tudo na mesma branch, porque a remoção de Projetos e a migração do frontend precisam entrar juntas.
