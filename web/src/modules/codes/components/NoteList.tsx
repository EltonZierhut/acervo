import { useEffect, useState } from 'react'
import { NavLink, useSearchParams } from 'react-router-dom'
import { useDebounce } from '../../../core/hooks'
import type { Paginated, SnippetSummary } from '../types'

interface Props {
  data: Paginated<SnippetSummary> | null
  loading: boolean
  error: string | null
}

export function NoteList({ data, loading, error }: Props) {
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const debounced = useDebounce(query.trim(), 300)
  const page = Number(params.get('page') ?? 1)
  const search = params.toString() ? `?${params}` : ''

  const update = (key: string, value: string) =>
    setParams(
      (current) => {
        const next = new URLSearchParams(current)
        if (value) next.set(key, value)
        else next.delete(key)
        if (key !== 'page') next.delete('page')
        return next
      },
      { replace: true },
    )

  useEffect(() => {
    if (debounced !== (params.get('q') ?? '')) update('q', debounced)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debounced])

  const filtered = Boolean(params.get('q'))

  return (
    <div className="note-list">
      <input
        className="search"
        type="search"
        autoFocus
        aria-label="Buscar notas"
        placeholder="Buscar por título, tag ou trecho…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      {error && <p className="error">{error}</p>}
      {loading && !data && <p className="muted">Carregando…</p>}

      {data && data.data.length === 0 && (
        <div className="empty">
          {filtered ? (
            <>
              <p>Nada encontrado.</p>
              <button
                type="button"
                onClick={() => {
                  setQuery('')
                  setParams(new URLSearchParams(), { replace: true })
                }}
              >
                Limpar busca
              </button>
            </>
          ) : (
            'Nenhuma nota ainda. Crie uma e cole o que quiser guardar.'
          )}
        </div>
      )}

      <ul className="note-items">
        {data?.data.map((note) => (
          <li key={note.id}>
            <NavLink to={`/codigos/${note.id}${search}`} className="note-item">
              <span className="note-item-title">{note.display_title}</span>
              <span className="muted small note-item-meta">
                {new Date(note.updated_at).toLocaleDateString('pt-BR')}
                {note.tags.length > 0 && ` · ${note.tags.map((t) => `#${t}`).join(' ')}`}
              </span>
            </NavLink>
          </li>
        ))}
      </ul>

      {data && data.meta.total_pages > 1 && (
        <div className="pagination">
          <button disabled={page <= 1} onClick={() => update('page', String(page - 1))}>Anterior</button>
          <span className="small">{page} de {data.meta.total_pages}</span>
          <button disabled={page >= data.meta.total_pages} onClick={() => update('page', String(page + 1))}>Próxima</button>
        </div>
      )}
    </div>
  )
}
