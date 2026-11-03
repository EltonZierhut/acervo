import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { formatDate, formatDateTime, isOverdue, PRIORITY_LABELS, RUN_STATUS_LABELS } from '../labels'
import type { Milestone, Task } from '../types'

interface ViewProps {
  task: Task
  milestone?: Milestone
}

export function TaskCardView({ task, milestone }: ViewProps) {
  const run = task.latest_run
  const overdue = isOverdue(task.due_on, task.status === 'done')
  return (
    <>
      <span className="card-title">{task.title}</span>
      <span className="card-meta small">
        <span className="card-number muted">#{task.number}</span>
        <span className={`priority priority-${task.priority}`} title="Prioridade">{PRIORITY_LABELS[task.priority]}</span>
        {milestone && <span className="card-milestone muted" title="Marco">◆ {milestone.title}</span>}
        {task.due_on && (
          <span className={overdue ? 'overdue' : 'muted'} title={overdue ? 'Atrasada' : 'Prazo'}>
            {formatDate(task.due_on)}
          </span>
        )}
        {task.description && <span className="muted" title="Tem descrição" aria-label="Tem descrição">≡</span>}
      </span>
      {run && run.status === 'pr_open' && (
        <span className="card-run small muted">
          {RUN_STATUS_LABELS[run.status]} {formatDateTime(run.finished_at ?? run.started_at ?? run.enqueued_at)} · {run.repository}
          {run.pull_request_url && (
            <>
              {' · '}
              <a
                href={run.pull_request_url}
                target="_blank"
                rel="noreferrer"
                onClick={(event) => event.stopPropagation()}
                onPointerDown={(event) => event.stopPropagation()}
                onKeyDown={(event) => event.stopPropagation()}
              >
                Abrir PR
              </a>
            </>
          )}
        </span>
      )}
    </>
  )
}

interface Props extends ViewProps {
  onOpen: (task: Task) => void
}

export function SortableTaskCard({ task, milestone, onOpen }: Props) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: task.id })
  return (
    <li
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      className={`task-card${task.status === 'done' ? ' done' : ''}${isDragging ? ' dragging' : ''}`}
      {...attributes}
      {...listeners}
      aria-label={`Tarefa #${task.number}: ${task.title}`}
      onClick={() => onOpen(task)}
      onKeyDown={(event) => {
        listeners?.onKeyDown?.(event)
        if (event.key === 'Enter' && !event.defaultPrevented) onOpen(task)
      }}
    >
      <TaskCardView task={task} milestone={milestone} />
    </li>
  )
}
