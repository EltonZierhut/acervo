import { EditorContent, mergeAttributes, useEditor, useEditorState } from '@tiptap/react'
import type { Editor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { TaskItem } from '@tiptap/extension-task-item'
import { TaskList } from '@tiptap/extension-task-list'

// Item de checklist sem a caixinha no HTML salvo: o HTML guardado e sanitizado no servidor
// fica só com <li data-type="taskItem" data-checked>, e a caixinha é desenhada pelo editor.
const ChecklistItem = TaskItem.extend({
  renderHTML({ HTMLAttributes }) {
    return ['li', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, { 'data-type': this.name }), 0]
  },
})

interface Props {
  // HTML salvo (já sanitizado pelo servidor).
  value: string
  onChange: (html: string) => void
}

// Imagens não são suportadas: o esquema do editor não tem esse nó, então elas somem da colagem.
// Arquivos colados ou soltos são engolidos aqui para o navegador não abri-los nem inserir nada.
function pastedOnlyFiles(data: DataTransfer | null) {
  return Boolean(data && data.files.length > 0 && !data.getData('text/plain').trim())
}

function normalizeUrl(input: string) {
  const url = input.trim()
  return /^[a-z][a-z0-9+.-]*:/i.test(url) ? url : `https://${url}`
}

export default function RichTextEditor({ value, onChange }: Props) {
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3] },
        underline: false,
        strike: false,
        horizontalRule: false,
        link: { openOnClick: false, autolink: true },
      }),
      TaskList,
      ChecklistItem.configure({ nested: true }),
    ],
    content: value,
    editorProps: {
      attributes: { class: 'rich-content', role: 'textbox', 'aria-multiline': 'true', 'aria-label': 'Descrição' },
      handlePaste: (_view, event) => pastedOnlyFiles(event.clipboardData),
      handleDrop: (_view, event) => event.dataTransfer !== null && event.dataTransfer.files.length > 0,
    },
    onUpdate: ({ editor: current }) => onChange(current.isEmpty ? '' : current.getHTML()),
  })

  return (
    <div className="rich-editor">
      {editor && <Toolbar editor={editor} />}
      <EditorContent editor={editor} />
    </div>
  )
}

function Toolbar({ editor }: { editor: Editor }) {
  const active = useEditorState({
    editor,
    selector: ({ editor: e }) => ({
      bold: e.isActive('bold'),
      italic: e.isActive('italic'),
      h1: e.isActive('heading', { level: 1 }),
      h2: e.isActive('heading', { level: 2 }),
      h3: e.isActive('heading', { level: 3 }),
      bullet: e.isActive('bulletList'),
      ordered: e.isActive('orderedList'),
      tasks: e.isActive('taskList'),
      quote: e.isActive('blockquote'),
      code: e.isActive('codeBlock'),
      link: e.isActive('link'),
    }),
  })

  const setLink = () => {
    const previous = (editor.getAttributes('link').href as string | undefined) ?? ''
    const input = window.prompt('Endereço do link (deixe vazio para remover)', previous)
    if (input === null) return
    const chain = editor.chain().focus().extendMarkRange('link')
    if (input.trim() === '') chain.unsetLink().run()
    else chain.setLink({ href: normalizeUrl(input) }).run()
  }

  // onMouseDown evita que o clique tire o foco do editor.
  const button = (label: string, title: string, isActive: boolean, run: () => void) => (
    <button
      type="button"
      className={isActive ? 'active' : undefined}
      title={title}
      aria-label={title}
      aria-pressed={isActive}
      onMouseDown={(e) => e.preventDefault()}
      onClick={run}
    >
      {label}
    </button>
  )

  const chain = () => editor.chain().focus()
  return (
    <div className="rich-toolbar" role="toolbar" aria-label="Formatação">
      {button('N', 'Negrito', active.bold, () => chain().toggleBold().run())}
      {button('I', 'Itálico', active.italic, () => chain().toggleItalic().run())}
      {button('T1', 'Título 1', active.h1, () => chain().toggleHeading({ level: 1 }).run())}
      {button('T2', 'Título 2', active.h2, () => chain().toggleHeading({ level: 2 }).run())}
      {button('T3', 'Título 3', active.h3, () => chain().toggleHeading({ level: 3 }).run())}
      {button('• Lista', 'Lista', active.bullet, () => chain().toggleBulletList().run())}
      {button('1. Lista', 'Lista numerada', active.ordered, () => chain().toggleOrderedList().run())}
      {button('☑ Checklist', 'Checklist', active.tasks, () => chain().toggleTaskList().run())}
      {button('Link', 'Link', active.link, setLink)}
      {button('❝ Citação', 'Citação', active.quote, () => chain().toggleBlockquote().run())}
      {button('</> Código', 'Bloco de código', active.code, () => chain().toggleCodeBlock().run())}
    </div>
  )
}
