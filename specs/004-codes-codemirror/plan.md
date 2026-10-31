# Plano de implementação: Editor de código nas notas

**Branch**: `004-codes-codemirror` | **Data**: 2026-10-31 | **Spec**: [spec.md](spec.md)

**Entrada**: especificação em `specs/004-codes-codemirror/spec.md`

## Resumo

Trocar o `textarea` de conteúdo do `NoteEditor` por um componente `CodeEditor` baseado no CodeMirror 6,
montado com uma lista própria de extensões: números de linha, destaque da linha atual, Tab para indentar,
busca em português e realce pela linguagem da nota. O editor e cada linguagem são baixados só quando
usados. O salvamento automático, a API e os dados não mudam.

## Contexto técnico

**Linguagem/versão**: TypeScript com React 19 e Vite 8. Sem alterações no backend.

**Dependências principais**: novas, todas da família CodeMirror 6: `@codemirror/state`, `view`, `commands`, `search`, `language`, `legacy-modes`, `lang-css`, `lang-go`, `lang-html`, `lang-java`, `lang-javascript`, `lang-json`, `lang-python`, `lang-rust`, `lang-sql`, `lang-yaml` e `@lezer/highlight`.

**Armazenamento**: não muda ([data-model.md](data-model.md)).

**Testes**: `npm run build` e `npm run lint`, além do roteiro manual em [quickstart.md](quickstart.md). O frontend não tem executor de testes, e esta feature não introduz um (princípio II). `bin/rails test` não é afetado.

**Plataforma**: navegador; produção em Cloud Run. A imagem instala o que está no `package-lock.json`.

**Tipo de projeto**: aplicação web (`api/` + `web/`); só `web/` muda.

**Metas de desempenho**: nota de 1 MB abre em até 2 s, com digitação sem atraso perceptível (SC-003); o carregamento inicial não recebe o editor (SC-004).

**Restrições**: o texto não pode ser reformatado (FR-006); abrir uma nota não pode gerar salvamento (FR-008).

**Escala/escopo**: um componente novo, um mapa de linguagens e ajustes no `NoteEditor` e no CSS.

## Constitution Check

*Conferido antes da pesquisa e novamente depois do desenho, com o mesmo resultado.*

| Princípio | Situação | Observação |
|-----------|----------|------------|
| I. Modularidade | Passa | Tudo fica em `web/src/modules/codes/`; nada vai para o núcleo, pois só este módulo usa o editor. |
| II. Simplicidade | Passa, com justificativa | Dependências novas justificadas abaixo. Sem wrapper para React nem executor de testes. |
| III. Busca | Passa | A coluna `searchable` e a busca entre notas não mudam. A busca dentro da nota é coberta pelo FR-010. |
| IV. Contrato de API | Passa | Nenhuma mudança na API. |
| V. Qualidade verificável | Passa | Build e lint sem erros, e roteiro manual para o que eles não cobrem. |
| VI. Idioma | Passa | O painel de busca do editor, em inglês por padrão, é traduzido ([research.md](research.md), decisão 5). |

**Justificativa das dependências (princípio II)**: o `textarea` nativo não oferece números de linha nem
realce, e a busca precisa funcionar dentro do próprio editor. O CodeMirror foi pedido pelo usuário. Os
pacotes são separados por função, então só entram os usados. Esta decisão substitui a decisão 4 de
`specs/003-codes-quick-notes/research.md`.

## Estrutura do projeto

### Documentação (esta feature)

```text
specs/004-codes-codemirror/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/code-editor.md
└── tasks.md             # criado por /speckit-tasks
```

### Código-fonte

```text
web/
├── package.json, package-lock.json     # dependências novas
└── src/
    ├── index.css                       # altura do editor e cores do realce nos dois temas
    └── modules/codes/
        ├── components/
        │   ├── CodeEditor.tsx          # novo: integração com o CodeMirror, carregado sob demanda
        │   ├── editorLanguages.ts      # novo: linguagem da nota → pacote de realce
        │   └── NoteEditor.tsx          # usa o CodeEditor; trata falha de carregamento
        └── useAutosave.ts              # sem alterações
```

**Decisão de estrutura**: o editor é um componente do módulo Códigos. Se outro módulo precisar dele, passa
para `web/src/core/` nessa ocasião.

## Riscos

- **Comportamento em nota real**: o build e o lint não exercitam o editor. Foco, colagem, Ctrl+F, Tab e nota de 1 MB dependem do roteiro manual.
- **Tamanho final do pacote**: os valores de [research.md](research.md) vêm de um build de teste, não do código final. O roteiro confere o resultado real.

## Complexity Tracking

Sem violações a justificar.
