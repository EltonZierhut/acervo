import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { ExecutorStatus } from '../components/ExecutorStatus'
import { RunQuestions } from '../components/RunQuestions'
import { ACTIVE_RUN_STATUSES, entries, RUN_STATUS_LABELS, timeAgo } from '../labels'
import type { Run } from '../types'

// Momento em que a execução entrou no estado atual.
function stateSince(run: Run) {
  return run.finished_at ?? run.started_at ?? run.enqueued_at
}

export function QueuePage() {
  const [params, setParams] = useSearchParams()
  const status = params.get('status') ?? ''
  const page = Number(params.get('pagina')) || 1
  const [search, setSearch] = useState(params.get('q') ?? '')
  const q = useDebounce(search)
  const [actionError, setActionError] = useState<string | null>(null)

  const runs = useAsync(() => initiativesApi.listRuns({ q, status, page }), [q, status, page])
  const reload = runs.reload

  const update = (changes: Record<string, string>) => {
    const next = new URLSearchParams(params)
    Object.entries(changes).forEach(([key, value]) => (value ? next.set(key, value) : next.delete(key)))
    setParams(next, { replace: true })
  }

  useEffect(() => {
    if ((params.get('q') ?? '') === q) return
    const next = new URLSearchParams(params)
    if (q) next.set('q', q)
    else next.delete('q')
    next.delete('pagina')
    setParams(next, { replace: true })
  }, [q, params, setParams])

  useEffect(() => {
    const timer = window.setInterval(reload, 10000)
    return () => window.clearInterval(timer)
  }, [reload])

  const cancel = async (run: Run) => {
    if (!window.confirm(`Cancelar a execução de "${run.task_title}"?`)) return
    setActionError(null)
    try {
      await initiativesApi.cancelRun(run.id)
      reload()
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Não foi possível cancelar')
    }
  }

  const meta = runs.data?.meta

  return (
    <section className="queue">
      <Link to="/iniciativas" className="back">← Iniciativas</Link>
      <header className="page-header">
        <h1>Fila</h1>
      </header>
      <ExecutorStatus />

      <div className="filters">
        <input type="search" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Buscar pelo título da tarefa" aria-label="Buscar" />
        <select value={status} onChange={(e) => update({ status: e.target.value, pagina: '' })} aria-label="Estado">
          <option value="">Todos os estados</option>
          {entries(RUN_STATUS_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
      </div>

      {runs.error && <p className="error">{runs.error}</p>}
      {actionError && <p className="error">{actionError}</p>}
      {runs.data?.data.length === 0 && <p className="empty">Nenhuma execução encontrada.</p>}

      <ul className="run-list">
        {runs.data?.data.map((run) => (
          <li key={run.id} className="run-card">
            <div className="run-card-row">
              <span className={`run-status run-${run.status}`}>{RUN_STATUS_LABELS[run.status]}</span>
              <Link to={`/iniciativas/${run.initiative_id}?aba=tarefas`} className="run-card-title">{run.task_title}</Link>
              <span className="muted small">{run.initiative_name} · {run.repository} · {timeAgo(stateSince(run))}</span>
              {run.pull_request_url && <a href={run.pull_request_url} target="_blank" rel="noreferrer">Abrir PR</a>}
              {ACTIVE_RUN_STATUSES.includes(run.status) && <button type="button" onClick={() => void cancel(run)}>Cancelar</button>}
            </div>
            {run.failure_reason && <p className="error small">{run.failure_reason}</p>}
            {run.status === 'waiting' && <RunQuestions run={run} onAnswered={reload} />}
          </li>
        ))}
      </ul>

      {meta && meta.total_pages > 1 && (
        <div className="pagination">
          <button type="button" disabled={page <= 1} onClick={() => update({ pagina: String(page - 1) })}>Anterior</button>
          <span className="muted small">Página {meta.page} de {meta.total_pages}</span>
          <button type="button" disabled={page >= meta.total_pages} onClick={() => update({ pagina: String(page + 1) })}>Próxima</button>
        </div>
      )}
    </section>
  )
}
