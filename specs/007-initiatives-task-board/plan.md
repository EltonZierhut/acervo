# Plano 007: Quadro de tarefas

## Dependências novas (constituição, princípio II)

| Pacote | Por quê | Alternativa descartada |
|---|---|---|
| `@tiptap/react`, `@tiptap/pm`, `@tiptap/starter-kit`, `@tiptap/extension-task-list`, `@tiptap/extension-task-item` | Editor de texto rico sobre o ProseMirror: negrito, listas, checklists, links, títulos, citação e código, e colagem de HTML que descarta fontes, cores e imagens porque o esquema do documento só aceita os nós e marcas liberados. O StarterKit já traz o link. | `contenteditable` à mão: reimplementaria seleção, desfazer e normalização de colagem, com muito risco. |
| `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities` | Arrastar entre colunas e reordenar, com toque (segurar um instante), mouse e teclado. | API nativa de drag-and-drop do HTML: mais simples, mas não funciona bem no celular nem no teclado. |

O editor é carregado sob demanda (`lazy`), só quando um modal abre, para não pesar o carregamento do quadro.
Nenhuma gem nova: a sanitização usa o `rails-html-sanitizer` que já vem com o Rails.

## Backend

- Migration `20261102000001`: `number` (por iniciativa, índice único), `position` (ordem na coluna),
  `description_text` (texto puro). A coluna gerada `searchable` é recriada com `description_text`. Os dados
  existentes são preenchidos: número pela ordem de criação, posição pela ordem que a lista já tinha, descrições
  antigas em parágrafos HTML. Reversível (o `down` volta a descrição para texto puro).
- `number` é nulável para o código antigo continuar criando tarefas durante a troca de versões do deploy; o
  model preenche o número no `before_save` quando faltar.
- `Initiatives::RichText`: sanitiza com `Rails::HTML5::SafeListSanitizer` (tags `p br h1-h3 strong b em i u s del
  code pre blockquote ul ol li a hr`; atributos `href`, `data-type`, `data-checked`; `<script>`, `<style>` e
  afins saem com o conteúdo; `javascript:` em `href` é descartado) e gera o texto puro. Texto sem tags vira
  parágrafos, então clientes antigos da API seguem funcionando.
- `Task`: `position` ao fim da coluna ao criar ou mudar de status; `move_to(status, index:, before_id:)`
  renumera a coluna numa transação, com a iniciativa bloqueada.
- API: `PATCH /api/v1/initiatives/tasks/:id/move` (`status` + `position` e/ou `before_id`); a listagem aceita
  `priority` e `number` e mantém a ordem do quadro também na busca. O executor passa a receber a descrição em
  texto puro.

## Frontend

- `TaskBoard` (colunas, filtros, DnD, criação rápida, endereço `?tarefa=<número>`), `TaskCard`, `TaskModal`
  (busca a tarefa pelo número; salvamento automático em `useTaskAutosave`, só os campos alterados),
  `RichTextEditor`. O botão voltar fecha o modal; um bloqueio de navegação salva antes de sair.
- Com filtros ativos, a posição do arrasto é enviada pelo card vizinho (`before_id`), porque há cards escondidos.
