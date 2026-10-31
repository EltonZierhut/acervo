import { useState } from 'react'
import { ApiError } from '../../../core/api'
import { codesApi } from '../api'
import type { Snippet } from '../types'
import { CodeBlock } from './CodeBlock'
import { Tags } from './Tags'

interface Props {
  note: Snippet
  onEdit: () => void
  onDeleted: () => void
}

export function NoteView({ note, onEdit, onDeleted }: Props) {
  const [confirming, setConfirming] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const remove = async () => {
    try {
      await codesApi.deleteSnippet(note.id)
      onDeleted()
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Não foi possível apagar a nota.')
    }
  }

  return (
    <article className="note-view">
      <header className="note-toolbar">
        <h2 className="note-title">{note.display_title}</h2>
        <div className="actions">
          {confirming ? (
            <>
              <span className="small">Apagar esta nota?</span>
              <button type="button" className="btn danger" onClick={() => void remove()}>Sim, apagar</button>
              <button type="button" onClick={() => setConfirming(false)}>Cancelar</button>
            </>
          ) : (
            <>
              <button type="button" onClick={onEdit}>Editar</button>
              <button type="button" className="btn danger" onClick={() => setConfirming(true)}>Apagar</button>
            </>
          )}
        </div>
      </header>
      {error && <p className="error">{error}</p>}
      <div className="meta">
        {note.language && <span className="badge">{note.language}</span>}
        <span className="muted small">Atualizada em {new Date(note.updated_at).toLocaleString('pt-BR')}</span>
      </div>
      {note.description && <p className="description">{note.description}</p>}
      <CodeBlock code={note.content} language={note.language} />
      <Tags tags={note.tags} />
    </article>
  )
}
