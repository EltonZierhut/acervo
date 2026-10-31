import { useEffect, useRef, useState } from 'react'
import { useBlocker } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { codesApi, LANGUAGES } from '../api'
import type { Snippet, SnippetInput } from '../types'
import { clearDraft, readDraft, useAutosave } from '../useAutosave'
import { SaveStatus } from './SaveStatus'

const toInput = (note: Snippet | null): SnippetInput => ({
  title: note?.title ?? '',
  description: note?.description ?? '',
  language: note?.language ?? '',
  content: note?.content ?? '',
  tags: note?.tags.join(', ') ?? '',
})

interface Props {
  note: Snippet | null
  onSaved: (note: Snippet) => void
  onDeleted: () => void
}

export function NoteEditor({ note, onSaved, onDeleted }: Props) {
  const [initial] = useState(() => toInput(note))
  const { form, state, message, setForm, flush, abandon, hasUnsaved, noteId } = useAutosave({
    id: note?.id ?? null,
    initial,
    onSaved,
  })
  const [draft, setDraft] = useState(() => readDraft(note?.id ?? null))
  const [flushFailed, setFlushFailed] = useState(false)
  const [copy, setCopy] = useState<'idle' | 'copied' | 'failed'>('idle')
  const [confirming, setConfirming] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const pasted = useRef(false)

  const set = (key: keyof SnippetInput, value: string, immediate = false) =>
    setForm({ ...form, [key]: value }, immediate)

  const blocker = useBlocker(({ currentLocation, nextLocation }) => {
    const next = nextLocation.pathname
    if (next === currentLocation.pathname || next === '/login' || next === `/codigos/${noteId()}`) return false
    return hasUnsaved()
  })

  // Tenta salvar ao sair; só pergunta ao usuário se não conseguir.
  useEffect(() => {
    if (blocker.state !== 'blocked') return
    void flush().then((ok) => {
      if (ok) blocker.proceed()
      else setFlushFailed(true)
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [blocker.state])

  useEffect(() => {
    const warn = (event: BeforeUnloadEvent) => {
      if (!hasUnsaved()) return
      void flush()
      event.preventDefault()
    }
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [flush, hasUnsaved])

  const copyContent = async () => {
    try {
      await navigator.clipboard.writeText(form.content)
      setCopy('copied')
    } catch {
      setCopy('failed')
    }
    setTimeout(() => setCopy('idle'), 4000)
  }

  const remove = async () => {
    const id = noteId()
    if (!id) return
    try {
      await flush()
      await codesApi.deleteSnippet(id)
      abandon()
      onDeleted()
    } catch (err) {
      setDeleteError(err instanceof ApiError ? err.message : 'Não foi possível apagar a nota.')
    }
  }

  return (
    <div className="note-editor">
      <div className="note-toolbar">
        <SaveStatus state={state} />
        <div className="actions">
          {confirming ? (
            <>
              <span className="small">Apagar esta nota?</span>
              <button type="button" className="btn danger" onClick={() => void remove()}>Sim, apagar</button>
              <button type="button" onClick={() => setConfirming(false)}>Cancelar</button>
            </>
          ) : (
            <>
              <button type="button" disabled={!form.content} onClick={() => void copyContent()}>
                {copy === 'copied' ? 'Copiado!' : 'Copiar'}
              </button>
              {note && <button type="button" className="btn danger" onClick={() => setConfirming(true)}>Apagar</button>}
            </>
          )}
        </div>
      </div>

      {copy === 'failed' && <p className="error small">Não foi possível copiar. Selecione o texto manualmente.</p>}
      {deleteError && <p className="error">{deleteError}</p>}

      {draft && (
        <div className="notice note-banner">
          <span>Há um rascunho que não chegou a ser salvo.</span>
          <button
            type="button"
            onClick={() => {
              setForm(draft, true)
              setDraft(null)
            }}
          >
            Restaurar
          </button>
          <button
            type="button"
            onClick={() => {
              clearDraft(note?.id ?? null)
              setDraft(null)
            }}
          >
            Descartar
          </button>
        </div>
      )}

      {flushFailed && blocker.state === 'blocked' && (
        <div className="notice note-banner">
          <span>Não foi possível salvar as alterações.</span>
          <button
            type="button"
            onClick={() => {
              setFlushFailed(false)
              blocker.reset()
            }}
          >
            Continuar editando
          </button>
          <button
            type="button"
            className="danger"
            onClick={() => {
              abandon()
              blocker.proceed()
            }}
          >
            Sair sem salvar
          </button>
        </div>
      )}

      {message && <p className="error">{message}</p>}

      <textarea
        className="code-input note-content"
        aria-label="Conteúdo"
        autoFocus
        spellCheck={false}
        wrap="off"
        placeholder="Cole aqui o script ou a nota. O salvamento é automático."
        value={form.content}
        onPaste={() => {
          pasted.current = true
        }}
        onChange={(e) => {
          set('content', e.target.value, pasted.current)
          pasted.current = false
        }}
      />

      <details className="note-details">
        <summary>Mais detalhes</summary>
        <div className="form">
          <label>Título<input value={form.title} maxLength={200} onChange={(e) => set('title', e.target.value)} /></label>
          <div className="row">
            <label>Tags<input value={form.tags} placeholder="separadas por vírgula" onChange={(e) => set('tags', e.target.value)} /></label>
            <label>
              Linguagem
              <input list="note-languages" value={form.language} onChange={(e) => set('language', e.target.value)} />
              <datalist id="note-languages">
                {LANGUAGES.map((language) => <option key={language} value={language} />)}
              </datalist>
            </label>
          </div>
          <label>Descrição<textarea rows={2} value={form.description} onChange={(e) => set('description', e.target.value)} /></label>
        </div>
      </details>
    </div>
  )
}
