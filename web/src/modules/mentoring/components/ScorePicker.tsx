interface Props {
  value: number | null
  onChange: (value: number | null) => void
  label: string
  clearLabel?: string
}

// Nota de 1 a 5 em botões grandes; tocar na nota escolhida de novo limpa.
export function ScorePicker({ value, onChange, label, clearLabel = 'Sem nota' }: Props) {
  return (
    <div className="mt-score" role="radiogroup" aria-label={label}>
      {[1, 2, 3, 4, 5].map((score) => (
        <button key={score} type="button" role="radio" aria-checked={value === score}
          className={`mt-score-btn${value === score ? ' active' : ''}`}
          onClick={() => onChange(value === score ? null : score)}>
          {score}
        </button>
      ))}
      {value !== null && (
        <button type="button" className="link-button small" onClick={() => onChange(null)}>{clearLabel}</button>
      )}
    </div>
  )
}
