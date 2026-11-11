import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { Markdown } from '../components/Markdown'
import { MarkdownField } from '../components/MarkdownField'
import { ProgressBar } from '../components/ProgressBar'
import { GOAL_STATUS, errorMessage, formatDate } from '../labels'
import type { Goal, GoalInput, GoalStatus, Mentorship } from '../types'

const PROGRESS_STEPS = Array.from({ length: 11 }, (_, i) => i * 10)

export function GoalsTab({ mentorship }: { mentorship: Mentorship }) {
  const list = useAsync(() => mentoringApi.listGoals(mentorship.id), [mentorship.id])
  const [title, setTitle] = useState('')
  const [editing, setEditing] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  const create = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim()) return
    setError(null)
    try {
      const goal = await mentoringApi.createGoal(mentorship.id, { title })
      setTitle('')
      setEditing(goal.id) // abre para preencher critério de sucesso e prazo
      list.reload()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const goals = list.data?.data ?? []

  return (
    <div className="mt-goals">
      <form className="quick-add card" onSubmit={create}>
        <div className="quick-add-row">
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Novo objetivo (ex.: conduzir 1:1 com o time)"
            aria-label="Título do objetivo" maxLength={200} />
          <button type="submit" className="btn primary" disabled={!title.trim()}>Criar</button>
        </div>
        {error && <p className="error">{error}</p>}
      </form>

      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}
      {list.data && goals.length === 0 && (
        <div className="empty">Nenhum objetivo ainda. Use as respostas do questionário para definir de 1 a 3 objetivos claros.</div>
      )}

      <ul className="card-list">
        {goals.map((goal) => (
          <li key={goal.id} className={`card mt-goal mt-goal-${goal.status}`}>
            {editing === goal.id ? (
              <GoalEditor goal={goal} onDone={() => { setEditing(null); list.reload() }} onCancel={() => setEditing(null)} />
            ) : (
              <GoalView goal={goal} onEdit={() => setEditing(goal.id)} onQuickUpdate={async (input) => {
                setError(null)
                try {
                  await mentoringApi.updateGoal(goal.id, input)
                  list.reload()
                } catch (err) {
                  setError(errorMessage(err))
                }
              }} />
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}

function GoalView({ goal, onEdit, onQuickUpdate }: { goal: Goal; onEdit: () => void; onQuickUpdate: (input: GoalInput) => Promise<void> }) {
  return (
    <>
      <div className="mt-goal-head">
        <button type="button" className="task-title card-title mt-goal-title" onClick={onEdit}>{goal.title}</button>
        <span className={`status mt-status-${goal.status}`}>{GOAL_STATUS[goal.status]}</span>
      </div>
      <div className="meta">
        {goal.status !== 'dropped' && <ProgressBar percent={goal.progress} label={`Progresso de ${goal.title}`} />}
        {goal.target_on && <span className={goal.overdue ? 'overdue' : 'muted'}>{goal.overdue ? 'Atrasado · ' : 'Prazo '}{formatDate(goal.target_on)}</span>}
        {goal.action_items.total > 0 && <span className="muted">{goal.action_items.done}/{goal.action_items.total} ações</span>}
      </div>
      {goal.success_criteria && (
        <div className="mt-criteria"><span className="small muted">Critério de sucesso</span><Markdown>{goal.success_criteria}</Markdown></div>
      )}
      <div className="actions mt-wrap">
        {goal.status !== 'achieved' && goal.status !== 'dropped' && (
          <label className="mt-inline-label">
            <span className="small muted">Progresso</span>
            <select value={goal.progress} onChange={(e) => onQuickUpdate({ progress: Number(e.target.value) })} aria-label="Progresso">
              {PROGRESS_STEPS.map((step) => <option key={step} value={step}>{step}%</option>)}
            </select>
          </label>
        )}
        {goal.status !== 'achieved' && (
          <button type="button" className="btn" onClick={() => onQuickUpdate({ status: 'achieved' })}>Alcancei</button>
        )}
        <button type="button" className="btn" onClick={onEdit}>Editar</button>
      </div>
    </>
  )
}

function GoalEditor({ goal, onDone, onCancel }: { goal: Goal; onDone: () => void; onCancel: () => void }) {
  const [form, setForm] = useState({
    title: goal.title, success_criteria: goal.success_criteria ?? '', description: goal.description ?? '',
    target_on: goal.target_on ?? '', status: goal.status, progress: goal.progress,
  })
  const [error, setError] = useState<string | null>(null)
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((c) => ({ ...c, [key]: value }))

  const save = async (event: FormEvent) => {
    event.preventDefault()
    try {
      await mentoringApi.updateGoal(goal.id, form)
      onDone()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const remove = async () => {
    if (!window.confirm(`Apagar o objetivo "${goal.title}"? As ações ligadas continuam, sem o vínculo.`)) return
    await mentoringApi.deleteGoal(goal.id)
    onDone()
  }

  return (
    <form className="form mt-edit" onSubmit={save}>
      <label>
        Objetivo
        <input value={form.title} onChange={(e) => set('title', e.target.value)} required maxLength={200} />
      </label>
      <MarkdownField label="Critério de sucesso" value={form.success_criteria} onChange={(v) => set('success_criteria', v)} rows={3}
        placeholder="Como vou saber que alcancei? Seja concreto: o quê, quanto, até quando." autoFocus={!goal.success_criteria} />
      <div className="row">
        <label>
          Prazo
          <input type="date" value={form.target_on} onChange={(e) => set('target_on', e.target.value)} />
        </label>
        <label>
          Situação
          <select value={form.status} onChange={(e) => set('status', e.target.value as GoalStatus)}>
            {Object.entries(GOAL_STATUS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </label>
      </div>
      <label>
        Progresso
        <select value={form.status === 'achieved' ? 100 : form.progress} onChange={(e) => set('progress', Number(e.target.value))}
          disabled={form.status === 'achieved'}>
          {PROGRESS_STEPS.map((step) => <option key={step} value={step}>{step}%</option>)}
        </select>
      </label>
      <MarkdownField label="Detalhes (opcional)" value={form.description} onChange={(v) => set('description', v)} rows={3}
        placeholder="Por que isso importa, ideias, recursos…" />
      {error && <p className="error">{error}</p>}
      <div className="actions mt-wrap">
        <button type="submit" className="btn primary" disabled={!form.title.trim()}>Salvar</button>
        <button type="button" className="btn" onClick={onCancel}>Cancelar</button>
        <button type="button" className="btn danger" onClick={remove}>Apagar</button>
      </div>
    </form>
  )
}
