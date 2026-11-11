import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { mentoringApi } from '../api'
import { errorMessage, formatDate } from '../labels'
import type { ActionItem, Goal } from '../types'

interface Props {
  mentorshipId: number
  items: ActionItem[]
  goals: Goal[]
  onChanged: () => void
  meetingId?: number // ações novas ficam ligadas a este encontro
  showMeeting?: boolean // mostra o encontro de origem em cada ação
  allowCreate?: boolean
}

// Lista de ações com criação rápida (título + Enter), concluir por toque e edição no próprio item.
export function ActionItemList({ mentorshipId, items, goals, onChanged, meetingId, showMeeting = true, allowCreate = true }: Props) {
  const [title, setTitle] = useState('')
  const [dueOn, setDueOn] = useState('')
  const [goalId, setGoalId] = useState('')
  const [editing, setEditing] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const openGoals = goals.filter((goal) => goal.status !== 'dropped')

  const create = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim()) return
    setSaving(true)
    setError(null)
    try {
      await mentoringApi.createActionItem(mentorshipId, {
        title, due_on: dueOn || null, goal_id: goalId ? Number(goalId) : null, meeting_id: meetingId ?? null,
      })
      setTitle('')
      setDueOn('')
      onChanged()
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const toggle = async (item: ActionItem) => {
    setError(null)
    try {
      await mentoringApi.updateActionItem(item.id, { done: !item.done })
      onChanged()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  return (
    <div className="mt-actions">
      {allowCreate && (
        <form className="mt-action-add card" onSubmit={create}>
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Nova ação combinada"
            aria-label="Título da ação" maxLength={200} />
          <div className="mt-action-add-row">
            <label className="mt-inline-label">
              <span className="small muted">Prazo</span>
              <input type="date" value={dueOn} onChange={(e) => setDueOn(e.target.value)} />
            </label>
            {openGoals.length > 0 && (
              <label className="mt-inline-label">
                <span className="small muted">Objetivo</span>
                <select value={goalId} onChange={(e) => setGoalId(e.target.value)}>
                  <option value="">Nenhum</option>
                  {openGoals.map((goal) => <option key={goal.id} value={goal.id}>{goal.title}</option>)}
                </select>
              </label>
            )}
            <button type="submit" className="btn primary" disabled={saving || !title.trim()}>Adicionar</button>
          </div>
        </form>
      )}
      {error && <p className="error">{error}</p>}
      {items.length === 0 && <p className="muted">Nenhuma ação aqui.</p>}
      <ul className="milestones">
        {items.map((item) => (
          <li key={item.id} className={`milestone${item.done ? ' done' : ''}`}>
            {editing === item.id ? (
              <ActionItemEditor item={item} goals={openGoals} onDone={() => { setEditing(null); onChanged() }}
                onCancel={() => setEditing(null)} />
            ) : (
              <div className="milestone-row mt-action-row">
                <input type="checkbox" checked={item.done} onChange={() => toggle(item)}
                  aria-label={item.done ? `Reabrir "${item.title}"` : `Concluir "${item.title}"`} />
                <button type="button" className="task-title mt-action-title" onClick={() => setEditing(item.id)}>{item.title}</button>
                <span className="task-meta small">
                  {item.due_on && <span className={item.overdue ? 'overdue' : 'muted'}>{item.overdue ? 'Atrasada · ' : ''}{formatDate(item.due_on)}</span>}
                  {item.goal_title && <span className="chip mt-chip-clip" title={item.goal_title}>{item.goal_title}</span>}
                  {showMeeting && item.meeting_id && (
                    <Link to={`/mentoria/encontros/${item.meeting_id}`} className="muted">Encontro de {formatDate(item.meeting_held_on)}</Link>
                  )}
                </span>
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}

function ActionItemEditor({ item, goals, onDone, onCancel }: { item: ActionItem; goals: Goal[]; onDone: () => void; onCancel: () => void }) {
  const [title, setTitle] = useState(item.title)
  const [dueOn, setDueOn] = useState(item.due_on ?? '')
  const [goalId, setGoalId] = useState(item.goal_id ? String(item.goal_id) : '')
  const [error, setError] = useState<string | null>(null)

  const save = async (event: FormEvent) => {
    event.preventDefault()
    try {
      await mentoringApi.updateActionItem(item.id, { title, due_on: dueOn || null, goal_id: goalId ? Number(goalId) : null })
      onDone()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const remove = async () => {
    if (!window.confirm(`Apagar a ação "${item.title}"?`)) return
    await mentoringApi.deleteActionItem(item.id)
    onDone()
  }

  return (
    <form className="form mt-edit" onSubmit={save}>
      <label>
        Ação
        <input value={title} onChange={(e) => setTitle(e.target.value)} required maxLength={200} autoFocus />
      </label>
      <div className="row">
        <label>
          Prazo
          <input type="date" value={dueOn} onChange={(e) => setDueOn(e.target.value)} />
        </label>
        <label>
          Objetivo
          <select value={goalId} onChange={(e) => setGoalId(e.target.value)}>
            <option value="">Nenhum</option>
            {goals.map((goal) => <option key={goal.id} value={goal.id}>{goal.title}</option>)}
            {item.goal_id && !goals.some((g) => g.id === item.goal_id) && <option value={item.goal_id}>{item.goal_title}</option>}
          </select>
        </label>
      </div>
      {error && <p className="error">{error}</p>}
      <div className="actions mt-wrap">
        <button type="submit" className="btn primary" disabled={!title.trim()}>Salvar</button>
        <button type="button" className="btn" onClick={onCancel}>Cancelar</button>
        <button type="button" className="btn danger" onClick={remove}>Apagar</button>
      </div>
    </form>
  )
}
