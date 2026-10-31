import type { Progress } from '../types'

export function ProgressBar({ progress, label = 'tarefas' }: { progress: Progress; label?: string }) {
  if (progress.total === 0) return <span className="muted small">Sem {label}</span>

  const percent = Math.round((progress.done / progress.total) * 100)
  return (
    <span className="progress" title={`${percent}%`}>
      <span
        className="progress-track"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={progress.total}
        aria-valuenow={progress.done}
        aria-label={`${progress.done} de ${progress.total} ${label} concluídas`}
      >
        <span className="progress-fill" style={{ width: `${percent}%` }} />
      </span>
      <span className="small muted">{progress.done}/{progress.total}</span>
    </span>
  )
}
