import { useEffect, useState } from 'react'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { ACTIVE_RUN_STATUSES, formatDateTime, RUN_STATUS_LABELS } from '../labels'
import type { Run, Task } from '../types'
import { RunQuestions } from './RunQuestions'

interface Props {
  task: Task
  repository: string | null
  onChanged: () => void
}

function blockReason(task: Task, repository: string | null, hasDescription: boolean) {
  if (task.status === 'done') return 'Tarefa concluída não vai para a fila.'
  if (!repository) return 'Conecte a iniciativa a um repositório acessível, na aba Detalhes.'
  if (!hasDescription) return 'Escreva e salve a descrição antes de enviar.'
  return null
}

export function TaskRunPanel({ task, repository, onChanged }: Props) {
  const runs = useAsync(() => initiativesApi.listTaskRuns(task.id), [task.id])
  const reloadRuns = runs.reload
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const current = runs.data?.[0] ?? null
  const active = current !== null && ACTIVE_RUN_STATUSES.includes(current.status)
  const blocked = blockReason(task, repository, Boolean(task.description))

  // Acompanha enquanto está na fila ou rodando.
  useEffect(() => {
    if (!active) return
    const timer = window.setInterval(reloadRuns, 10000)
    return () => window.clearInterval(timer)
  }, [active, reloadRuns])

  const act = async (action: () => Promise<unknown>) => {
    setBusy(true)
    setError(null)
    try {
      await action()
      runs.reload()
      onChanged()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível concluir')
    } finally {
      setBusy(false)
    }
  }

  const refresh = () => {
    runs.reload()
    onChanged()
  }

  const cancel = (run: Run) => {
    if (window.confirm('Cancelar esta execução?')) void act(() => initiativesApi.cancelRun(run.id))
  }

  return (
    <section className="task-section">
      <h4>Execução por IA</h4>
      {runs.error && <p className="error small">{runs.error}</p>}

      {current?.status === 'waiting' && <RunQuestions key={current.id} run={current} onAnswered={refresh} />}

      <div className="actions">
        {active
          ? current && <button type="button" disabled={busy} onClick={() => cancel(current)}>Cancelar execução</button>
          : (
            <button type="button" className="btn primary" disabled={busy || blocked !== null} onClick={() => void act(() => initiativesApi.enqueueTask(task.id))}>
              {current ? 'Enviar de novo' : 'Enviar para a fila'}
            </button>
          )}
        {blocked && !active && <span className="muted small">{blocked}</span>}
      </div>
      {error && <p className="error small">{error}</p>}

      {runs.data && runs.data.length > 0 && (
        <ol className="run-history">
          {runs.data.map((run) => (
            <li key={run.id}>
              <span className={`run-status run-${run.status}`}>{RUN_STATUS_LABELS[run.status]}</span>{' '}
              <span className="muted small">{formatDateTime(run.finished_at ?? run.started_at ?? run.enqueued_at)} · {run.repository}</span>
              {run.pull_request_url && <> · <a href={run.pull_request_url} target="_blank" rel="noreferrer">Abrir PR</a></>}
              {run.failure_reason && <p className="error small">{run.failure_reason}</p>}
              {run.summary && <p className="small pre">{run.summary}</p>}
              {run.questions.some((q) => q.answered_at) && (
                <ul className="small muted">
                  {run.questions.filter((q) => q.answered_at).map((q) => <li key={q.id}>{q.body} → {q.answer}</li>)}
                </ul>
              )}
            </li>
          ))}
        </ol>
      )}
    </section>
  )
}
