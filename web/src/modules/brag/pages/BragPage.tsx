import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { bragApi, formatDate } from '../api'
import { Markdown } from '../components/Markdown'

// Registro rápido: tocar no campo, digitar o título e tocar em "Registrar" (ou Enter) = 3 toques.
function QuickAdd({ onCreated }: { onCreated: () => void }) {
  const [title, setTitle] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim()) return
    setSaving(true)
    setError(null)
    try {
      await bragApi.createEntry({ title })
      setTitle('')
      onCreated()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível registrar')
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="quick-add card" onSubmit={submit}>
      <div className="quick-add-row">
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="O que você fez hoje?"
          aria-label="Título da conquista" maxLength={200} autoFocus />
        <button type="submit" className="btn primary" disabled={saving || !title.trim()}>Registrar</button>
      </div>
      <Link to="/brag/novo" className="small">Preencher mais campos</Link>
      {error && <p className="error">{error}</p>}
    </form>
  )
}

export function BragPage() {
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const debounced = useDebounce(query.trim(), 300)
  const q = params.get('q') ?? ''
  const page = Number(params.get('page') ?? 1)

  useEffect(() => {
    if (debounced === q) return
    setParams((current) => {
      const next = new URLSearchParams(current)
      if (debounced) next.set('q', debounced)
      else next.delete('q')
      next.delete('page')
      return next
    }, { replace: true })
  }, [debounced, q, setParams])

  const list = useAsync(() => bragApi.listEntries({ q, page }), [q, page])

  return (
    <section>
      <header className="page-header">
        <h1>Brag document</h1>
        <Link to="/brag/novo" className="btn">+ Detalhada</Link>
      </header>

      <QuickAdd onCreated={list.reload} />

      <div className="filters">
        <input className="search" type="search" aria-label="Buscar conquistas" placeholder="Buscar por título, tag, projeto…"
          value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>

      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}
      {list.data && list.data.data.length === 0 && (
        <div className="empty">{q ? 'Nada encontrado.' : 'Nenhuma conquista registrada ainda.'}</div>
      )}

      <ul className="card-list">
        {list.data?.data.map((entry) => (
          <li key={entry.id} className="card">
            <Link to={`/brag/${entry.id}`} className="card-title brag-title">{entry.title}</Link>
            <div className="meta">
              <span>{formatDate(entry.achieved_on)}</span>
              {entry.category && <span className="chip">{entry.category}</span>}
              {entry.project && <span className="muted">{entry.project}</span>}
              {entry.tags.map((tag) => <span key={tag} className="badge">{tag}</span>)}
            </div>
            {entry.description && <div className="clamp"><Markdown>{entry.description}</Markdown></div>}
          </li>
        ))}
      </ul>

      {list.data && list.data.meta.total_pages > 1 && (
        <div className="pager">
          <button type="button" disabled={page <= 1} onClick={() => setParams((c) => { const n = new URLSearchParams(c); n.set('page', String(page - 1)); return n })}>Anterior</button>
          <span className="muted small">Página {page} de {list.data.meta.total_pages}</span>
          <button type="button" disabled={page >= list.data.meta.total_pages} onClick={() => setParams((c) => { const n = new URLSearchParams(c); n.set('page', String(page + 1)); return n })}>Próxima</button>
        </div>
      )}
    </section>
  )
}
