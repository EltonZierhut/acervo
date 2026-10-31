import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { CONTEXT_COLORS } from '../labels'
import type { Context } from '../types'

function ColorPicker({ value, onChange }: { value: string; onChange: (color: string) => void }) {
  return (
    <span className="color-picker" role="radiogroup" aria-label="Cor">
      {CONTEXT_COLORS.map((color) => (
        <button
          key={color}
          type="button"
          role="radio"
          aria-checked={value === color}
          aria-label={color}
          className={value === color ? 'swatch selected' : 'swatch'}
          style={{ background: color }}
          onClick={() => onChange(color)}
        />
      ))}
    </span>
  )
}

function ContextRow({ context, onChanged }: { context: Context; onChanged: () => void }) {
  const [name, setName] = useState(context.name)
  const [color, setColor] = useState(context.color)
  const [error, setError] = useState<string | null>(null)
  const dirty = name !== context.name || color !== context.color

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    try {
      await initiativesApi.updateContext(context.id, { name, color })
      onChanged()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar')
    }
  }

  const remove = async () => {
    const note = context.initiatives_count > 0 ? ` As ${context.initiatives_count} iniciativa(s) dele ficam sem contexto.` : ''
    if (!window.confirm(`Apagar o contexto "${context.name}"?${note}`)) return
    await initiativesApi.deleteContext(context.id)
    onChanged()
  }

  return (
    <li className="card">
      <form className="context-row" onSubmit={save}>
        <input value={name} onChange={(e) => setName(e.target.value)} aria-label="Nome do contexto" required maxLength={60} />
        <ColorPicker value={color} onChange={setColor} />
        <span className="muted small">{context.initiatives_count} iniciativa(s)</span>
        <span className="actions">
          <button type="submit" className="btn primary" disabled={!dirty}>Salvar</button>
          <button type="button" className="btn danger" onClick={remove}>Apagar</button>
        </span>
      </form>
      {error && <p className="error">{error}</p>}
    </li>
  )
}

export function ContextsPage() {
  const contexts = useAsync(() => initiativesApi.listContexts(), [])
  const [name, setName] = useState('')
  const [color, setColor] = useState(CONTEXT_COLORS[0])
  const [error, setError] = useState<string | null>(null)

  const add = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    try {
      await initiativesApi.createContext({ name, color })
      setName('')
      contexts.reload()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível criar')
    }
  }

  return (
    <section>
      <Link to="/iniciativas" className="back">← Iniciativas</Link>
      <header className="page-header">
        <h1>Contextos</h1>
      </header>
      <p className="muted">Agrupe iniciativas por área: Trabalho, Casa, Jogo, Estudos…</p>

      <form className="context-row card" onSubmit={add}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Novo contexto" aria-label="Nome do novo contexto" required maxLength={60} />
        <ColorPicker value={color} onChange={setColor} />
        <button type="submit" className="btn primary" disabled={!name.trim()}>Criar</button>
      </form>
      {error && <p className="error">{error}</p>}

      {contexts.error && <p className="error">{contexts.error}</p>}
      {contexts.data && contexts.data.length === 0 && <div className="empty">Nenhum contexto ainda.</div>}
      <ul className="card-list context-list">
        {contexts.data?.map((context) => (
          <ContextRow key={`${context.id}-${context.name}-${context.color}`} context={context} onChanged={contexts.reload} />
        ))}
      </ul>
    </section>
  )
}
