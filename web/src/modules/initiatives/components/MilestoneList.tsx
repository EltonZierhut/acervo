import { useState } from 'react'
import type { FormEvent } from 'react'
import { initiativesApi } from '../api'
import { formatDate, isOverdue } from '../labels'
import type { Milestone } from '../types'
import { ProgressBar } from './ProgressBar'

interface Props {
  initiativeId: number
  milestones: Milestone[] | null
  loading: boolean
  error: string | null
  onChanged: () => void
}

interface Draft {
  title: string
  description: string
  due_on: string | null
}

function MilestoneItem({ milestone, onChanged }: { milestone: Milestone; onChanged: () => void }) {
  const [draft, setDraft] = useState<Draft | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const completed = milestone.completed_at !== null
  const overdue = isOverdue(milestone.due_on, completed)

  const run = async (action: () => Promise<unknown>) => {
    setBusy(true)
    setError(null)
    try {
      await action()
      onChanged()
      return true
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar')
      return false
    } finally {
      setBusy(false)
    }
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    if (draft && (await run(() => initiativesApi.updateMilestone(milestone.id, draft)))) setDraft(null)
  }

  const remove = () => {
    if (window.confirm(`Apagar o marco "${milestone.title}"? As tarefas ligadas a ele continuam, sem marco.`)) {
      void run(() => initiativesApi.deleteMilestone(milestone.id))
    }
  }

  return (
    <li className={`milestone${completed ? ' done' : ''}`}>
      <div className="milestone-row">
        <input
          type="checkbox"
          checked={completed}
          disabled={busy}
          onChange={() => run(() => initiativesApi.updateMilestone(milestone.id, { completed: !completed }))}
          aria-label={completed ? `Reabrir "${milestone.title}"` : `Concluir "${milestone.title}"`}
        />
        <button
          type="button"
          className="task-title"
          onClick={() =>
            setDraft(draft ? null : { title: milestone.title, description: milestone.description ?? '', due_on: milestone.due_on })
          }
        >
          {milestone.title}
        </button>
        <span className="small">
          {completed ? (
            <span className="muted">Concluído em {new Date(milestone.completed_at as string).toLocaleDateString('pt-BR')}</span>
          ) : milestone.due_on ? (
            <span className={overdue ? 'overdue' : 'muted'}>{overdue ? 'Atrasado · ' : ''}{formatDate(milestone.due_on)}</span>
          ) : (
            <span className="muted">Sem data</span>
          )}
        </span>
      </div>
      <div className="milestone-progress"><ProgressBar progress={milestone.progress} /></div>
      {milestone.description && !draft && <p className="description pre small">{milestone.description}</p>}
      {error && <p className="error small">{error}</p>}

      {draft && (
        <form className="form task-editor" onSubmit={save}>
          <div className="row">
            <label>
              Título
              <input value={draft.title} onChange={(e) => setDraft({ ...draft, title: e.target.value })} required maxLength={200} />
            </label>
            <label>
              Data-alvo
              <input type="date" value={draft.due_on ?? ''} onChange={(e) => setDraft({ ...draft, due_on: e.target.value || null })} />
            </label>
          </div>
          <label>
            Descrição
            <textarea rows={3} value={draft.description} onChange={(e) => setDraft({ ...draft, description: e.target.value })} />
          </label>
          <div className="actions">
            <button type="submit" className="btn primary" disabled={busy}>Salvar</button>
            <button type="button" onClick={() => setDraft(null)}>Cancelar</button>
            <button type="button" className="btn danger" onClick={remove} disabled={busy}>Apagar</button>
          </div>
        </form>
      )}
    </li>
  )
}

export function MilestoneList({ initiativeId, milestones, loading, error, onChanged }: Props) {
  const [title, setTitle] = useState('')
  const [dueOn, setDueOn] = useState('')
  const [adding, setAdding] = useState(false)
  const [addError, setAddError] = useState<string | null>(null)

  const add = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim()) return
    setAdding(true)
    setAddError(null)
    try {
      await initiativesApi.createMilestone(initiativeId, { title, due_on: dueOn || null })
      setTitle('')
      setDueOn('')
      onChanged()
    } catch (err) {
      setAddError(err instanceof Error ? err.message : 'Não foi possível criar o marco')
    } finally {
      setAdding(false)
    }
  }

  return (
    <div className="milestone-list">
      <form className="quick-add" onSubmit={add}>
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Novo marco… ex.: Protótipo jogável" aria-label="Título do novo marco" maxLength={200} disabled={adding} />
        <input type="date" value={dueOn} onChange={(e) => setDueOn(e.target.value)} aria-label="Data-alvo do novo marco" disabled={adding} />
        <button type="submit" className="btn primary" disabled={adding || !title.trim()}>Adicionar</button>
      </form>
      {addError && <p className="error">{addError}</p>}

      {error && <p className="error">{error}</p>}
      {loading && !milestones && <p className="muted">Carregando…</p>}
      {milestones && milestones.length === 0 && (
        <div className="empty">Nenhum marco ainda. Marcos são as grandes entregas ou fases da iniciativa.</div>
      )}
      <ul className="milestones">
        {milestones?.map((m) => <MilestoneItem key={`${m.id}-${m.updated_at}`} milestone={m} onChanged={onChanged} />)}
      </ul>
    </div>
  )
}
