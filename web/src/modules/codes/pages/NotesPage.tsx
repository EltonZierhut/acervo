import { useCallback, useEffect, useState } from 'react'
import { Link, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { useAsync } from '../../../core/hooks'
import { codesApi } from '../api'
import { NoteEditor } from '../components/NoteEditor'
import { NoteList } from '../components/NoteList'
import type { Snippet } from '../types'

interface PaneProps {
  id: number | null
  backTo: string
  onChanged: () => void
  onCreated: (note: Snippet) => void
  onDeleted: () => void
}

function NotePane({ id, backTo, onChanged, onCreated, onDeleted }: PaneProps) {
  const [note, setNote] = useState<Snippet | null>(null)
  const [loadError, setLoadError] = useState<{ status: number; message: string } | null>(null)
  const invalidId = id !== null && !Number.isInteger(id)

  // Só carrega ao abrir: durante a edição, a tela é a fonte do texto.
  useEffect(() => {
    if (id === null || invalidId) return
    let active = true
    codesApi
      .getSnippet(id)
      .then((loaded) => {
        if (active) setNote(loaded)
      })
      .catch((err: Error) => {
        if (active) setLoadError({ status: err instanceof ApiError ? err.status : 0, message: err.message })
      })
    return () => {
      active = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (invalidId || loadError?.status === 404) {
    return (
      <div className="empty">
        <p>Nota não encontrada.</p>
        <Link to={backTo}>Voltar para a lista</Link>
      </div>
    )
  }
  if (loadError) return <p className="error">{loadError.message}</p>

  if (id !== null && !note) return <p className="muted">Carregando…</p>

  return (
    <NoteEditor
      note={note}
      onSaved={(saved) => {
        const created = !note
        setNote(saved)
        if (created) onCreated(saved)
        onChanged()
      }}
      onDeleted={onDeleted}
    />
  )
}

export function NotesPage() {
  const params = useParams()
  const [searchParams] = useSearchParams()
  const { search } = useLocation()
  const navigate = useNavigate()

  const isNew = params.id === 'novo'
  const routeId = params.id && !isNew ? Number(params.id) : null
  const hasPane = params.id !== undefined
  const backTo = `/codigos${search}`

  // A nota recém-criada mantém a chave do painel, para o editor seguir aberto com o texto.
  const [newKey, setNewKey] = useState(0)
  const [created, setCreated] = useState<{ id: number; key: string } | null>(null)
  const paneKey = isNew ? `new-${newKey}` : created && created.id === routeId ? created.key : `note-${params.id}`

  const q = searchParams.get('q')
  const page = searchParams.get('page')
  const list = useAsync(
    () => codesApi.listSnippets({ q: q ?? undefined, page: Number(page ?? 1) }),
    [q, page],
  )
  const reloadList = list.reload
  const onChanged = useCallback(() => void reloadList(), [reloadList])

  return (
    <section className={hasPane ? 'notes has-note' : 'notes'}>
      <aside className="notes-side">
        <header className="page-header">
          <h1>Códigos</h1>
          <Link
            to={`/codigos/novo${search}`}
            className="btn primary"
            onClick={() => setNewKey((key) => key + 1)}
          >
            + Nova nota
          </Link>
        </header>
        <NoteList data={list.data} loading={list.loading} error={list.error} />
      </aside>

      <div className="notes-pane">
        <Link to={backTo} className="back notes-back">← Voltar para a lista</Link>
        {hasPane ? (
          <NotePane
            key={paneKey}
            id={isNew ? null : routeId}
            backTo={backTo}
            onChanged={onChanged}
            onCreated={(note) => {
              setCreated({ id: note.id, key: `new-${newKey}` })
              navigate(`/codigos/${note.id}${search}`, { replace: true })
            }}
            onDeleted={() => {
              onChanged()
              navigate(backTo)
            }}
          />
        ) : (
          <div className="empty">Selecione uma nota ou crie uma nova.</div>
        )}
      </div>
    </section>
  )
}
