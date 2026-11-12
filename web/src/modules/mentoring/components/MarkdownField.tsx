import { useId, useState } from 'react'
import { Markdown } from './Markdown'

interface Props {
  label: string
  value: string
  onChange: (value: string) => void
  rows?: number
  placeholder?: string
  autoFocus?: boolean
}

// Campo de texto em Markdown com alternância Editar / Visualizar (funciona por toque).
export function MarkdownField({ label, value, onChange, rows = 5, placeholder, autoFocus }: Props) {
  const id = useId()
  const [preview, setPreview] = useState(false)

  return (
    <div className="label-block">
      <div className="label-line">
        <label htmlFor={id}>{label}</label>
        <button type="button" className="small-btn" onClick={() => setPreview((v) => !v)} aria-pressed={preview}>
          {preview ? 'Editar' : 'Visualizar'}
        </button>
      </div>
      {preview ? (
        <div className="markdown-preview">
          {value.trim() ? <Markdown>{value}</Markdown> : <p className="muted">Nada para visualizar.</p>}
        </div>
      ) : (
        <textarea id={id} rows={rows} value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
          autoFocus={autoFocus} />
      )}
    </div>
  )
}
