import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync, useDebounce } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { entries, TASK_STATUS_LABELS } from '../labels'
import type { Milestone, Task, TaskStatus } from '../types'
import { TaskItem } from './TaskItem'

interface Props {
  initiativeId: number
  repository: string | null
  // null quando a seção Marcos está desligada.
  milestones: Milestone[] | null
  onChanged: () => void
}

const GROUPS: TaskStatus[] = ['doing', 'todo', 'done']

export function TaskList({ initiativeId, repository, milestones, onChanged }: Props) {
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('')
  const [milestoneId, setMilestoneId] = useState('')
  const [title, setTitle] = useState('')
  const [adding, setAdding] = useState(false)
  const [addError, setAddError] = useState<string | null>(null)
  const q = useDebounce(query.trim(), 300)

  const tasks = useAsync(
    () => initiativesApi.listTasks(initiativeId, { q, status, milestone_id: milestones ? milestoneId : '' }),
    [initiativeId, q, status, milestoneId, milestones === null],
  )

  const changed = () => {
    tasks.reload()
    onChanged()
  }

  // Criação rápida: Enter cria e o campo continua pronto para a próxima.
  const add = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim()) return
    setAdding(true)
    setAddError(null)
    try {
      const linked = milestones && /^\d+$/.test(milestoneId) ? Number(milestoneId) : null
      await initiativesApi.createTask(initiativeId, { title, milestone_id: linked })
      setTitle('')
      changed()
    } catch (err) {
      setAddError(err instanceof Error ? err.message : 'Não foi possível criar a tarefa')
    } finally {
      setAdding(false)
    }
  }

  const byStatus = (group: TaskStatus) => tasks.data?.data.filter((t: Task) => t.status === group) ?? []
  const filtered = Boolean(q || status || milestoneId)

  return (
    <div className="task-list">
      <form className="quick-add" onSubmit={add}>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Nova tarefa… (Enter para adicionar)"
          aria-label="Título da nova tarefa"
          maxLength={300}
          disabled={adding}
          autoFocus
        />
        <button type="submit" className="btn primary" disabled={adding || !title.trim()}>Adicionar</button>
      </form>
      {addError && <p className="error">{addError}</p>}

      <div className="filters">
        <input className="search" type="search" placeholder="Buscar tarefas…" aria-label="Buscar tarefas" value={query} onChange={(e) => setQuery(e.target.value)} />
        <select value={status} onChange={(e) => setStatus(e.target.value)} aria-label="Filtrar por status">
          <option value="">Todos os status</option>
          {entries(TASK_STATUS_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
        {milestones && milestones.length > 0 && (
          <select value={milestoneId} onChange={(e) => setMilestoneId(e.target.value)} aria-label="Filtrar por marco">
            <option value="">Todos os marcos</option>
            <option value="none">Sem marco</option>
            {milestones.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
          </select>
        )}
      </div>

      {tasks.error && <p className="error">{tasks.error}</p>}
      {tasks.loading && !tasks.data && <p className="muted">Carregando…</p>}
      {tasks.data?.meta.truncated && (
        <p className="notice">Mostrando as primeiras {tasks.data.data.length} de {tasks.data.meta.total} tarefas. Use a busca para refinar.</p>
      )}

      {tasks.data && tasks.data.data.length === 0 && (
        <div className="empty">{filtered ? 'Nenhuma tarefa encontrada.' : 'Nenhuma tarefa ainda. Digite acima e aperte Enter.'}</div>
      )}

      {GROUPS.map((group) => {
        const items = byStatus(group)
        if (items.length === 0) return null
        return (
          <section key={group} className="task-group">
            <h3>{TASK_STATUS_LABELS[group]} <span className="muted small">{items.length}</span></h3>
            <ul className="task-items">
              {items.map((task) => (
                <TaskItem key={task.id} task={task} repository={repository} milestones={milestones} onChanged={changed} />
              ))}
            </ul>
          </section>
        )
      })}
    </div>
  )
}
