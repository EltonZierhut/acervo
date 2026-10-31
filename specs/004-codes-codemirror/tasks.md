# Tarefas: Editor de código nas notas

**Entrada**: `specs/004-codes-codemirror/` (spec, plano, pesquisa, modelo de dados, contrato e guia de validação)

**Testes**: sem tarefas de teste automatizado. A spec não os pede, a API não muda e o frontend não tem executor de testes. A verificação é feita com build, lint e o roteiro de quickstart.md.

**Formato**: `[P]` pode rodar em paralelo; `[USn]` é a história da spec.

## Fase 1: Preparação

- [X] T001 Instalar em web/package.json e web/package-lock.json os pacotes `@codemirror/state`, `@codemirror/view`, `@codemirror/commands`, `@codemirror/search`, `@codemirror/language`, `@codemirror/legacy-modes`, `@codemirror/lang-css`, `@codemirror/lang-go`, `@codemirror/lang-html`, `@codemirror/lang-java`, `@codemirror/lang-javascript`, `@codemirror/lang-json`, `@codemirror/lang-python`, `@codemirror/lang-rust`, `@codemirror/lang-sql`, `@codemirror/lang-yaml` e `@lezer/highlight`, sem incluir `codemirror` nem `@uiw/react-codemirror`

## Fase 2: Base (bloqueia todas as histórias)

- [X] T002 Criar web/src/modules/codes/components/CodeEditor.tsx com `export default` e as propriedades de contracts/code-editor.md: criar o `EditorView` em um `useEffect` e destruí-lo ao desmontar, compatível com o StrictMode, com `initialValue` como documento inicial
- [X] T003 Trocar o `textarea` de conteúdo em web/src/modules/codes/components/NoteEditor.tsx pelo `CodeEditor` com `React.lazy` e `Suspense` em volta só do editor, com o aviso "Carregando editor…", mantendo `aria-label` "Conteúdo" e o placeholder atual e removendo a ref `pasted`; o estado de `useAutosave` continua no `NoteEditor`, e web/src/modules/codes/useAutosave.ts não muda

## Fase 3: História 1 - Editar em um editor de código (P1)

**Objetivo**: números de linha, linha atual destacada, Tab para indentar e temas.

**Teste independente**: itens 1, 2, 12, 13 e 14 de quickstart.md.

- [X] T004 [US1] Montar em web/src/modules/codes/components/CodeEditor.tsx a lista própria de extensões (research.md, decisão 2): `lineNumbers`, `highlightActiveLine`, `highlightActiveLineGutter`, `history`, `drawSelection`, `bracketMatching`, `placeholder`, `defaultKeymap`, `historyKeymap` e `indentWithTab`, sem `basicSetup`, `autocompletion`, `closeBrackets`, `indentOnInput` nem `EditorView.lineWrapping`
- [X] T005 [US1] Definir em web/src/modules/codes/components/CodeEditor.tsx `EditorView.contentAttributes` com `aria-label`, `spellcheck="false"`, `autocorrect="off"` e `autocapitalize="off"`, e chamar `view.focus()` ao montar (FR-002, FR-003, FR-011)
- [X] T006 [US1] Criar em web/src/modules/codes/components/CodeEditor.tsx o `EditorView.theme` com as variáveis CSS existentes (`--surface`, `--text`, `--border`, `--muted`, `--accent`, `--accent-soft`) e a fonte da classe `.code-input`, sem cor fixa (FR-004)
- [X] T007 [US1] Em web/src/index.css, trocar a regra `.note-content` por um contêiner com `height: 60vh`, `min-height: 60vh`, `resize: vertical` e `overflow: hidden`, com `.cm-editor` em 100% de altura e o estado de foco igual ao dos demais campos, e aplicar a classe em volta do `CodeEditor` em web/src/modules/codes/components/NoteEditor.tsx (FR-012)

## Fase 4: História 2 - Manter o fluxo de colar e salvar (P1)

**Objetivo**: nenhuma regressão no fluxo atual, e texto salvo idêntico ao colado.

**Teste independente**: itens 3 a 9, 11 e 15 a 17 de quickstart.md.

- [X] T008 [US2] Em web/src/modules/codes/components/CodeEditor.tsx, adicionar o `updateListener` que chama `onChange(texto, pasted)` só se `update.docChanged`, com `pasted` vindo de `transaction.isUserEvent('input.paste')`, mantendo a versão mais recente de `onChange` em uma ref atualizada por efeito, como o `onSavedRef` de useAutosave.ts
- [X] T009 [US2] Em web/src/modules/codes/components/NoteEditor.tsx, mudar a `key` do `CodeEditor` ao "Restaurar" um rascunho, para o editor remontar com o texto restaurado (FR-007, FR-008; substitui a sincronização de `value`, ver research.md, decisão 3)
- [X] T010 [US2] Em web/src/modules/codes/components/NoteEditor.tsx, ligar `onChange` a `set('content', value, pasted)`, mantendo "Copiar" sobre `form.content` (FR-005, FR-007)
- [X] T011 [US2] Em web/src/modules/codes/components/CodeEditor.tsx, adicionar `search()` e `searchKeymap` e traduzir com `EditorState.phrases` todos os textos do painel de busca e de "ir para a linha" para o português (FR-010, princípio VI)
- [X] T012 [P] [US2] Estilizar o painel de busca com as variáveis CSS, em web/src/modules/codes/components/CodeEditor.tsx ou web/src/index.css, para os dois temas ficarem legíveis
- [X] T013 [US2] Em web/src/modules/codes/components/NoteEditor.tsx, criar um limite de erro em volta do `Suspense` que mostre "Não foi possível carregar o editor. Recarregue a página." com a classe `error`, sem desmontar a barra de ações nem "Mais detalhes" (casos extremos)

## Fase 5: História 3 - Realce de sintaxe (P2)

**Objetivo**: realce conforme a linguagem da nota, trocando sem recarregar.

**Teste independente**: item 10 de quickstart.md.

- [X] T014 [P] [US3] Criar web/src/modules/codes/components/editorLanguages.ts com um mapa de `import()` dinâmicos para cada item de `LANGUAGES` de web/src/modules/codes/api.ts: `bash` e `ruby` com `StreamLanguage.define` e os modos `shell` e `ruby` de `@codemirror/legacy-modes`, `typescript` com `javascript({ typescript: true })` e as demais com `lang-*`, comparando o nome sem diferenciar maiúsculas e sem espaços nas pontas, e devolvendo `null` para valor fora do mapa
- [X] T015 [US3] Em web/src/modules/codes/components/CodeEditor.tsx, adicionar um `Compartment` para a linguagem e um efeito sobre `language` que carrega a extensão e faz `reconfigure`, descartando resultado de uma troca antiga e ficando em texto simples se o carregamento falhar, sem mover o cursor e sem criar item no desfazer (FR-009)
- [X] T016 [US3] Criar o `HighlightStyle.define` com `var(--syntax-*)` em web/src/modules/codes/components/CodeEditor.tsx e definir essas variáveis nos temas claro e escuro em web/src/index.css, com contraste legível (FR-004, FR-009)
- [X] T017 [US3] Em web/src/modules/codes/components/NoteEditor.tsx, passar `language={form.language}` ao `CodeEditor`

## Fase 6: Acabamento

- [X] T018 [P] Registrar em specs/003-codes-quick-notes/research.md, na decisão 4, que ela foi substituída por specs/004-codes-codemirror/research.md
- [X] T019 Conferir com `grep` que `.note-content` e `.code-input` em web/src/index.css e `textarea` no `NoteEditor` só permanecem onde ainda são usados, e remover o que sobrar
- [X] T020 Rodar `npm run build` e `npm run lint` em web/ e conferir no resultado do build que o editor e as linguagens estão em arquivos separados do `index-*.js` (SC-004); registrar os tamanhos reais em specs/004-codes-codemirror/research.md, decisão 4
- [X] T021 Validar no navegador todos os itens de specs/004-codes-codemirror/quickstart.md

## Dependências

- T001 vem antes de tudo; T002 e T003 bloqueiam as histórias.
- US1 e US2 dependem só da Fase 2, mas tocam os mesmos arquivos; faça-as em sequência. US2 é necessária para o produto mínimo, porque sem ela nada é salvo.
- US3 depende da Fase 2. T015 usa o mapa da T014, e T017 usa o efeito da T015.
- Paralelo: T012 com as outras tarefas da US2 só se ficar em web/src/index.css; T014 com qualquer tarefa da US1 e da US2; T018 com qualquer tarefa.

## Estratégia

Produto mínimo com as fases 1 a 4: o editor substitui o `textarea` sem regressões. Validar e depois adicionar o realce e o acabamento. Tudo entra na mesma branch e em um só PR, já que trocar o editor sem as garantias da US2 colocaria em risco as notas.
