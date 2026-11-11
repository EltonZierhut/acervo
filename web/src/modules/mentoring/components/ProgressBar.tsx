// Barra de progresso em porcentagem.
export function ProgressBar({ percent, label }: { percent: number; label: string }) {
  const value = Math.max(0, Math.min(100, Math.round(percent)))
  return (
    <span className="progress">
      <span className="progress-track" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={value} aria-label={label}>
        <span className="progress-fill" style={{ width: `${value}%` }} />
      </span>
      <span className="small muted">{value}%</span>
    </span>
  )
}
