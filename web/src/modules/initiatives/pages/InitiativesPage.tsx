import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { ContextBadge } from '../components/ContextBadge'
import { ProgressBar } from '../components/ProgressBar'
import { entries, formatDate, isOverdue, PRIORITY_LABELS, STATUS_LABELS } from '../labels'

export function InitiativesPage() {
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const debounced = useDebounce(query.trim(), 300)

  const q = params.get('q') ?? ''
  const status = params.get('status') ?? ''
  const contextId = params.get('contexto') ?? ''
  const page = Number(params.get('page') ?? 1)

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
    if (debounced !== q) update('q', debounced)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debounced])

  const contexts = useAsync(() => initiativesApi.listContexts(), [])
  const list = useAsync(
    () => initiativesApi.listInitiatives({ q, status, context_id: contextId, page }),
    [q, status, contextId, page],
  )
  const filtered = Boolean(q || status || contextId)

  return (
    <section>
      <header className="page-header">
        <h1>Iniciativas</h1>
        <div className="actions">
          <Link to="/iniciativas/contextos" className="btn">Contextos</Link>
          <Link to="/iniciativas/nova" className="btn primary">+ Nova iniciativa</Link>
        </div>
      </header>

      <div className="filters">
        <input
          className="search"
          type="search"
          autoFocus
          aria-label="Buscar iniciativas"
          placeholder="Buscar por nome, descrição ou tag…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <select value={status} onChange={(e) => update('status', e.target.value)} aria-label="Filtrar por status">
          <option value="">Em aberto</option>
          {entries(STATUS_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          <option value="all">Todas</option>
        </select>
        <select value={contextId} onChange={(e) => update('contexto', e.target.value)} aria-label="Filtrar por contexto">
          <option value="">Todos os contextos</option>
          <option value="none">Sem contexto</option>
          {contexts.data?.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </div>

      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}

      {list.data && list.data.data.length === 0 && (
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
                Limpar filtros
              </button>
            </>
          ) : (
            'Nenhuma iniciativa ainda. Crie uma para cada coisa que você está tocando: um projeto, um jogo, uma reforma.'
          )}
        </div>
      )}

      <ul className="card-list grid">
        {list.data?.data.map((initiative) => {
          const overdue = isOverdue(initiative.due_on, initiative.status === 'done')
          return (
            <li key={initiative.id}>
              <Link
                to={`/iniciativas/${initiative.id}`}
                className="card initiative-card"
                style={initiative.context ? { borderTopColor: initiative.context.color } : undefined}
              >
                <span className="card-title">{initiative.name}</span>
                <span className="meta">
                  <span className={`status status-${initiative.status}`}>{STATUS_LABELS[initiative.status]}</span>
                  {initiative.priority !== 'medium' && (
                    <span className={`priority priority-${initiative.priority}`}>{PRIORITY_LABELS[initiative.priority]}</span>
                  )}
                  <ContextBadge context={initiative.context} />
                </span>
                <ProgressBar progress={initiative.progress} />
                <span className="small">
                  {initiative.due_on && (
                    <span className={overdue ? 'overdue' : 'muted'}>Alvo: {formatDate(initiative.due_on)}</span>
                  )}
                  {initiative.tags.length > 0 && <span className="muted"> {initiative.tags.map((t) => `#${t}`).join(' ')}</span>}
                </span>
              </Link>
            </li>
          )
        })}
      </ul>

      {list.data && list.data.meta.total_pages > 1 && (
        <div className="pagination">
          <button disabled={page <= 1} onClick={() => update('page', String(page - 1))}>Anterior</button>
          <span className="small">{page} de {list.data.meta.total_pages}</span>
          <button disabled={page >= list.data.meta.total_pages} onClick={() => update('page', String(page + 1))}>Próxima</button>
        </div>
      )}
    </section>
  )
}
