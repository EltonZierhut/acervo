import { useState } from 'react'
import type { FormEvent } from 'react'
import { initiativesApi } from '../api'
import { entries, formatDate, isOverdue, PRIORITY_LABELS, RUN_STATUS_LABELS, TASK_STATUS_OPTIONS } from '../labels'
import type { Milestone, Task, TaskInput } from '../types'
import { TaskImages } from './TaskImages'
import { TaskLinks } from './TaskLinks'
import { TaskRunPanel } from './TaskRunPanel'

interface Props {
  task: Task
  repository: string | null
  milestones: Milestone[] | null
  onChanged: () => void
}

export function TaskItem({ task, repository, milestones, onChanged }: Props) {
  const [editing, setEditing] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<TaskInput>({})
  const done = task.status === 'done'
  const overdue = isOverdue(task.due_on, done)
  const milestone = milestones?.find((m) => m.id === task.milestone_id)

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

  const toggleDone = () => run(() => initiativesApi.updateTask(task.id, { status: done ? 'todo' : 'done' }))

  const openEditor = () => {
    setForm({
      title: task.title,
      description: task.description ?? '',
      status: task.status,
      priority: task.priority,
      due_on: task.due_on,
      milestone_id: task.milestone_id,
    })
    setEditing(true)
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    if (await run(() => initiativesApi.updateTask(task.id, form))) setEditing(false)
  }

  const remove = () => {
    if (window.confirm(`Apagar a tarefa "${task.title}"?`)) void run(() => initiativesApi.deleteTask(task.id))
  }

  const set = <K extends keyof TaskInput>(key: K, value: TaskInput[K]) => setForm((f) => ({ ...f, [key]: value }))

  return (
    <li className={`task-item${done ? ' done' : ''}`}>
      <div className="task-row">
        <input
          type="checkbox"
          checked={done}
          disabled={busy}
          onChange={toggleDone}
          aria-label={done ? `Reabrir "${task.title}"` : `Concluir "${task.title}"`}
        />
        <button type="button" className="task-title" onClick={() => (editing ? setEditing(false) : openEditor())}>
          {task.title}
        </button>
        <span className="task-meta small">
          {(task.images_count > 0 || task.links_count > 0) && (
            <span className="muted">
              {task.images_count > 0 && `${task.images_count} ${task.images_count === 1 ? 'imagem' : 'imagens'}`}
              {task.images_count > 0 && task.links_count > 0 && ' · '}
              {task.links_count > 0 && `${task.links_count} ${task.links_count === 1 ? 'link' : 'links'}`}
            </span>
          )}
          {task.latest_run && (
            task.latest_run.pull_request_url
              ? <a className={`run-status run-${task.latest_run.status}`} href={task.latest_run.pull_request_url} target="_blank" rel="noreferrer">{RUN_STATUS_LABELS[task.latest_run.status]}</a>
              : <span className={`run-status run-${task.latest_run.status}`}>{RUN_STATUS_LABELS[task.latest_run.status]}</span>
          )}
          {task.priority !== 'medium' && (
            <span className={`priority priority-${task.priority}`}>{PRIORITY_LABELS[task.priority]}</span>
          )}
          {milestone && <span className="muted">◆ {milestone.title}</span>}
          {task.due_on && (
            <span className={overdue ? 'overdue' : 'muted'}>
              {overdue ? 'Atrasada · ' : ''}{formatDate(task.due_on)}
            </span>
          )}
        </span>
      </div>

      {error && !editing && <p className="error small">{error}</p>}

      {editing && (
        <form className="form task-editor" onSubmit={save}>
          <label>
            Título
            <input value={form.title ?? ''} onChange={(e) => set('title', e.target.value)} required maxLength={300} />
          </label>
          <label>
            Descrição
            <textarea rows={3} value={form.description ?? ''} onChange={(e) => set('description', e.target.value)} />
          </label>
          <div className="row">
            <label>
              Status
              <select value={form.status} onChange={(e) => set('status', e.target.value as Task['status'])}>
                {entries(TASK_STATUS_OPTIONS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
            <label>
              Prioridade
              <select value={form.priority} onChange={(e) => set('priority', e.target.value as Task['priority'])}>
                {entries(PRIORITY_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </select>
            </label>
          </div>
          <div className="row">
            <label>
              Prazo
              <input type="date" value={form.due_on ?? ''} onChange={(e) => set('due_on', e.target.value || null)} />
            </label>
            {milestones && (
              <label>
                Marco
                <select
                  value={form.milestone_id ?? ''}
                  onChange={(e) => set('milestone_id', e.target.value ? Number(e.target.value) : null)}
                >
                  <option value="">Sem marco</option>
                  {milestones.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
                </select>
              </label>
            )}
          </div>
          {error && <p className="error">{error}</p>}
          <div className="actions">
            <button type="submit" className="btn primary" disabled={busy}>Salvar</button>
            <button type="button" onClick={() => setEditing(false)}>Cancelar</button>
            <button type="button" className="btn danger" onClick={remove} disabled={busy}>Apagar</button>
          </div>
        </form>
      )}

      {editing && (
        <div className="task-extras">
          <TaskImages taskId={task.id} onChanged={onChanged} />
          <TaskLinks taskId={task.id} onChanged={onChanged} />
          <TaskRunPanel task={task} repository={repository} onChanged={onChanged} />
        </div>
      )}
    </li>
  )
}
