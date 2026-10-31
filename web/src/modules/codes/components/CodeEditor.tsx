import { defaultKeymap, history, historyKeymap, indentWithTab } from '@codemirror/commands'
import { bracketMatching, HighlightStyle, syntaxHighlighting } from '@codemirror/language'
import { search, searchKeymap } from '@codemirror/search'
import { Compartment, EditorState } from '@codemirror/state'
import {
  drawSelection,
  EditorView,
  highlightActiveLine,
  highlightActiveLineGutter,
  keymap,
  lineNumbers,
  placeholder as placeholderText,
} from '@codemirror/view'
import { tags } from '@lezer/highlight'
import { useEffect, useRef } from 'react'
import { loadLanguage } from './editorLanguages'

const phrases = EditorState.phrases.of({
  Find: 'Buscar',
  Replace: 'Substituir',
  next: 'próximo',
  previous: 'anterior',
  all: 'todos',
  'match case': 'diferenciar maiúsculas',
  regexp: 'expressão regular',
  'by word': 'palavra inteira',
  replace: 'substituir',
  'replace all': 'substituir todos',
  close: 'fechar',
  'current match': 'resultado atual',
  'on line': 'na linha',
  'replaced $ matches': '$ resultados substituídos',
  'replaced match on line $': 'resultado substituído na linha $',
  'Go to line': 'Ir para a linha',
  go: 'ir',
  'Selection deleted': 'Seleção apagada',
  'Control character': 'Caractere de controle',
})

// As cores vêm das variáveis do index.css, então o editor acompanha o tema do sistema sozinho.
const theme = EditorView.theme({
  '&': { height: '100%', color: 'var(--text)', backgroundColor: 'var(--surface)' },
  '&.cm-focused': { outline: 'none' },
  '.cm-scroller': { fontFamily: 'inherit', lineHeight: '1.5' },
  '.cm-content': { caretColor: 'var(--text)' },
  '.cm-cursor, .cm-dropCursor': { borderLeftColor: 'var(--text)' },
  '.cm-gutters': { color: 'var(--muted)', backgroundColor: 'var(--surface)', borderRight: '1px solid var(--border)' },
  '.cm-activeLine': { backgroundColor: 'color-mix(in srgb, var(--accent) 7%, transparent)' },
  '.cm-activeLineGutter': { backgroundColor: 'var(--accent-soft)', color: 'var(--text)' },
  '.cm-selectionBackground, &.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground': {
    backgroundColor: 'color-mix(in srgb, var(--accent) 30%, transparent)',
  },
  '.cm-placeholder': { color: 'var(--muted)' },
  '.cm-matchingBracket, &.cm-focused .cm-matchingBracket': {
    backgroundColor: 'color-mix(in srgb, var(--accent) 22%, transparent)',
    color: 'inherit',
  },
  '.cm-searchMatch': { backgroundColor: 'var(--search-match)', outline: 'none' },
  '.cm-searchMatch.cm-searchMatch-selected': { backgroundColor: 'var(--search-match-current)' },
  '.cm-panels': { color: 'var(--text)', backgroundColor: 'var(--surface)' },
  '.cm-panels.cm-panels-top': { borderBottom: '1px solid var(--border)' },
  '.cm-panels.cm-panels-bottom': { borderTop: '1px solid var(--border)' },
  '.cm-panel.cm-search': { fontFamily: 'system-ui, sans-serif' },
  '.cm-panel.cm-search label': { display: 'inline-flex', alignItems: 'center', gap: '4px', color: 'var(--text)' },
  // O index.css deixa todo input com largura total; aqui eles dividem a linha.
  '.cm-panel.cm-search input[type=checkbox]': { width: 'auto', margin: '0', padding: '0' },
  '.cm-panel.cm-search .cm-textfield': { width: 'auto', padding: '4px 8px', borderRadius: '6px' },
  '.cm-panel.cm-search [name=close]': { color: 'var(--muted)' },
  '.cm-textfield': { color: 'var(--text)', backgroundColor: 'var(--bg)', border: '1px solid var(--border)' },
  '.cm-button': { color: 'var(--text)', backgroundImage: 'none', backgroundColor: 'var(--bg)', border: '1px solid var(--border)' },
})

const highlightStyle = HighlightStyle.define([
  { tag: [tags.keyword, tags.modifier, tags.operatorKeyword], color: 'var(--syntax-keyword)' },
  { tag: [tags.string, tags.special(tags.string), tags.regexp], color: 'var(--syntax-string)' },
  { tag: tags.comment, color: 'var(--syntax-comment)', fontStyle: 'italic' },
  { tag: [tags.number, tags.bool, tags.null, tags.atom], color: 'var(--syntax-number)' },
  { tag: [tags.function(tags.variableName), tags.function(tags.propertyName), tags.macroName], color: 'var(--syntax-function)' },
  { tag: [tags.typeName, tags.className, tags.tagName, tags.namespace], color: 'var(--syntax-type)' },
  { tag: [tags.attributeName, tags.propertyName, tags.meta], color: 'var(--syntax-attribute)' },
  { tag: tags.invalid, color: 'var(--danger)' },
])

interface Props {
  initialValue: string
  language: string
  placeholder: string
  ariaLabel: string
  onChange: (value: string, pasted: boolean) => void
}

// O texto só entra ao montar: durante a edição, o documento é a fonte. Para trocá-lo, mude a `key`.
export default function CodeEditor({ initialValue, language, placeholder, ariaLabel, onChange }: Props) {
  const parentRef = useRef<HTMLDivElement>(null)
  const viewRef = useRef<EditorView | null>(null)
  const languageRef = useRef(new Compartment())
  const onChangeRef = useRef(onChange)
  useEffect(() => {
    onChangeRef.current = onChange
  })

  useEffect(() => {
    const view = new EditorView({
      parent: parentRef.current!,
      state: EditorState.create({
        doc: initialValue,
        extensions: [
          lineNumbers(),
          highlightActiveLineGutter(),
          highlightActiveLine(),
          history(),
          drawSelection(),
          bracketMatching(),
          search({ top: true }),
          placeholderText(placeholder),
          keymap.of([...defaultKeymap, ...historyKeymap, ...searchKeymap, indentWithTab]),
          EditorState.tabSize.of(2),
          EditorView.contentAttributes.of({
            'aria-label': ariaLabel,
            spellcheck: 'false',
            autocorrect: 'off',
            autocapitalize: 'off',
          }),
          EditorView.updateListener.of((update) => {
            if (!update.docChanged) return
            const pasted = update.transactions.some((transaction) => transaction.isUserEvent('input.paste'))
            onChangeRef.current(update.state.doc.toString(), pasted)
          }),
          phrases,
          theme,
          syntaxHighlighting(highlightStyle),
          languageRef.current.of([]),
        ],
      }),
    })
    viewRef.current = view
    view.focus()
    return () => {
      view.destroy()
      viewRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    let active = true
    const apply = (extension: Parameters<Compartment['reconfigure']>[0]) => {
      if (active) viewRef.current?.dispatch({ effects: languageRef.current.reconfigure(extension) })
    }
    // Se a linguagem não puder ser baixada, o conteúdo fica como texto simples.
    loadLanguage(language).then(apply, () => apply([]))
    return () => {
      active = false
    }
  }, [language])

  return <div ref={parentRef} className="code-input note-content" />
}
