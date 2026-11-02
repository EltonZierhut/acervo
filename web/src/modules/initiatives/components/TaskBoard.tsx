import { useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import {
  closestCorners, DndContext, DragOverlay, KeyboardSensor, MouseSensor, TouchSensor, useDroppable, useSensor, useSensors,
} from '@dnd-kit/core'
import type { DragEndEvent, DragOverEvent, DragStartEvent, UniqueIdentifier } from '@dnd-kit/core'
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { useAsync, useDebounce } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { BOARD_COLUMNS, BOARD_LABELS, entries, PRIORITY_LABELS } from '../labels'
import type { Milestone, Task, TaskStatus } from '../types'
import { SortableTaskCard, TaskCardView } from './TaskCard'
import { TaskModal } from './TaskModal'

interface Props {
  initiativeId: number
  repository: string | null
  // null quando a seção Marcos está desligada.
  milestones: Milestone[] | null
  onChanged: () => void
}

type Columns = Record<TaskStatus, Task[]>

const COLUMN_PREFIX = 'col:'
const columnId = (status: TaskStatus) => `${COLUMN_PREFIX}${status}`

function group(tasks: Task[]): Columns {
  const columns: Columns = { todo: [], doing: [], done: [] }
  tasks.forEach((task) => columns[task.status].push(task))
  return columns
}

export function TaskBoard({ initiativeId, repository, milestones, onChanged }: Props) {
  const [query, setQuery] = useState('')
  const [priority, setPriority] = useState('')
  const [milestoneId, setMilestoneId] = useState('')
  const [moveError, setMoveError] = useState<string | null>(null)
  const q = useDebounce(query.trim(), 300)
  const filtered = Boolean(q || priority || milestoneId)

  const tasks = useAsync(
    () => initiativesApi.listTasks(initiativeId, { q, priority, milestone_id: milestones ? milestoneId : '' }),
    [initiativeId, q, priority, milestoneId, milestones === null],
  )
  const reloadTasks = tasks.reload

  const [columns, setColumns] = useState<Columns>({ todo: [], doing: [], done: [] })
  const [dragging, setDragging] = useState<Task | null>(null)
  const dragOrigin = useRef<TaskStatus | null>(null)
  // As colunas seguem a resposta da API; durante o arrasto elas mudam localmente.
  const [syncedData, setSyncedData] = useState(tasks.data)
  if (tasks.data !== syncedData) {
    setSyncedData(tasks.data)
    if (tasks.data) setColumns(group(tasks.data.data))
  }

  // A tarefa aberta fica no endereço (?tarefa=12) para dar para compartilhar o link e o botão voltar fechar o modal.
  const [params, setParams] = useSearchParams()
  const navigate = useNavigate()
  const location = useLocation()
  const openNumber = /^\d+$/.test(params.get('tarefa') ?? '') ? Number(params.get('tarefa')) : null

  const openTask = (task: Task) => {
    const next = new URLSearchParams(params)
    next.set('tarefa', String(task.number))
    void navigate({ search: next.toString() }, { state: { fromBoard: true } })
  }
  const closeTask = () => {
    if ((location.state as { fromBoard?: boolean } | null)?.fromBoard) {
      void navigate(-1)
      return
    }
    const next = new URLSearchParams(params)
    next.delete('tarefa')
    setParams(next, { replace: true })
  }

  const refresh = () => {
    reloadTasks()
    onChanged()
  }

  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 6 } }),
    // No celular, segurar um instante começa o arrasto; arrastar logo de cara rola a tela.
    useSensor(TouchSensor, { activationConstraint: { delay: 250, tolerance: 8 } }),
    // Enter abre o modal; o arrasto pelo teclado começa com Espaço.
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
      keyboardCodes: { start: ['Space'], cancel: ['Escape'], end: ['Space', 'Enter'] },
    }),
  )

  const columnOf = (id: UniqueIdentifier, from: Columns): TaskStatus | null => {
    if (typeof id === 'string') return BOARD_COLUMNS.find((s) => columnId(s) === id) ?? null
    return BOARD_COLUMNS.find((s) => from[s].some((t) => t.id === id)) ?? null
  }

  const onDragStart = ({ active }: DragStartEvent) => {
    const task = BOARD_COLUMNS.flatMap((s) => columns[s]).find((t) => t.id === active.id) ?? null
    setDragging(task)
    dragOrigin.current = task?.status ?? null
    setMoveError(null)
  }

  // Ao passar por cima de outra coluna, o card já aparece nela.
  const onDragOver = ({ active, over }: DragOverEvent) => {
    if (!over) return
    setColumns((prev) => {
      const from = columnOf(active.id, prev)
      const to = columnOf(over.id, prev)
      if (!from || !to || from === to) return prev
      const moving = prev[from].find((t) => t.id === active.id)
      if (!moving) return prev
      const overIndex = prev[to].findIndex((t) => t.id === over.id)
      const translated = active.rect.current.translated
      const below = translated !== null && translated.top > over.rect.top + over.rect.height / 2
      const index = overIndex >= 0 ? overIndex + (below ? 1 : 0) : prev[to].length
      return {
        ...prev,
        [from]: prev[from].filter((t) => t.id !== active.id),
        [to]: [...prev[to].slice(0, index), { ...moving, status: to }, ...prev[to].slice(index)],
      }
    })
  }

  const onDragEnd = ({ active, over }: DragEndEvent) => {
    const origin = dragOrigin.current
    setDragging(null)
    dragOrigin.current = null
    const to = columnOf(active.id, columns)
    if (!origin || !to) return

    let final = columns[to]
    if (over && typeof over.id === 'number') {
      const from = final.findIndex((t) => t.id === active.id)
      const target = final.findIndex((t) => t.id === over.id)
      if (from >= 0 && target >= 0 && from !== target) {
        final = arrayMove(final, from, target)
        setColumns((prev) => ({ ...prev, [to]: final }))
      }
    }
    const index = final.findIndex((t) => t.id === active.id)
    const previous = tasks.data?.data.filter((t) => t.status === to).findIndex((t) => t.id === active.id) ?? -1
    if (origin === to && index === previous) return

    // Com filtros ligados a posição se mede pelo card vizinho, porque há cards escondidos na coluna.
    const next = final[index + 1]
    const move = next ? { before_id: next.id, position: filtered ? undefined : index } : { position: filtered ? undefined : index }
    initiativesApi
      .moveTask(Number(active.id), { status: to, ...move })
      .catch((err: Error) => setMoveError(err.message || 'Não foi possível mover a tarefa'))
      .finally(refresh)
  }

  const onDragCancel = () => {
    setDragging(null)
    dragOrigin.current = null
    if (tasks.data) setColumns(group(tasks.data.data))
  }

  const create = async (status: TaskStatus, title: string) => {
    const linked = milestones && /^\d+$/.test(milestoneId) ? Number(milestoneId) : null
    await initiativesApi.createTask(initiativeId, { title, status, milestone_id: linked })
    refresh()
  }

  const milestoneOf = (task: Task) => milestones?.find((m) => m.id === task.milestone_id)

  return (
    <div className="task-board">
      <div className="filters">
        <input className="search" type="search" placeholder="Buscar tarefas…" aria-label="Buscar tarefas" value={query} onChange={(e) => setQuery(e.target.value)} />
        <select value={priority} onChange={(e) => setPriority(e.target.value)} aria-label="Filtrar por prioridade">
          <option value="">Todas as prioridades</option>
          {entries(PRIORITY_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
        </select>
        {milestones && milestones.length > 0 && (
          <select value={milestoneId} onChange={(e) => setMilestoneId(e.target.value)} aria-label="Filtrar por marco">
            <option value="">Todos os marcos</option>
            <option value="none">Sem marco</option>
            {milestones.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
          </select>
        )}
      </div>

      {(tasks.error || moveError) && <p className="error">{moveError ?? tasks.error}</p>}
      {tasks.loading && !tasks.data && <p className="muted">Carregando…</p>}
      {tasks.data?.meta.truncated && (
        <p className="notice">Mostrando as primeiras {tasks.data.data.length} de {tasks.data.meta.total} tarefas. Use a busca para refinar.</p>
      )}

      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={onDragStart}
        onDragOver={onDragOver}
        onDragEnd={onDragEnd}
        onDragCancel={onDragCancel}
      >
        <div className="board">
          {BOARD_COLUMNS.map((status) => (
            <BoardColumn
              key={status}
              status={status}
              tasks={columns[status]}
              milestoneOf={milestoneOf}
              onOpen={openTask}
              onCreate={(title) => create(status, title)}
            />
          ))}
        </div>
        <DragOverlay>
          {dragging && (
            <div className="task-card overlay">
              <TaskCardView task={dragging} milestone={milestoneOf(dragging)} />
            </div>
          )}
        </DragOverlay>
      </DndContext>

      {openNumber !== null && (
        <TaskModal
          key={openNumber}
          initiativeId={initiativeId}
          number={openNumber}
          repository={repository}
          milestones={milestones}
          onClose={closeTask}
          onChanged={refresh}
        />
      )}
    </div>
  )
}

interface ColumnProps {
  status: TaskStatus
  tasks: Task[]
  milestoneOf: (task: Task) => Milestone | undefined
  onOpen: (task: Task) => void
  onCreate: (title: string) => Promise<void>
}

function BoardColumn({ status, tasks, milestoneOf, onOpen, onCreate }: ColumnProps) {
  const { setNodeRef, isOver } = useDroppable({ id: columnId(status) })
  const [creating, setCreating] = useState(false)
  const [title, setTitle] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Enter cria o card e o campo continua pronto para o próximo.
  const submit = async (event: FormEvent) => {
    event.preventDefault()
    if (!title.trim() || busy) return
    setBusy(true)
    setError(null)
    try {
      await onCreate(title)
      setTitle('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível criar a tarefa')
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className={`board-column${isOver ? ' over' : ''}`} aria-label={BOARD_LABELS[status]}>
      <h3>
        {BOARD_LABELS[status]} <span className="muted small">{tasks.length}</span>
      </h3>
      <SortableContext items={tasks.map((t) => t.id)} strategy={verticalListSortingStrategy}>
        <ul ref={setNodeRef} className="board-cards">
          {tasks.map((task) => (
            <SortableTaskCard key={task.id} task={task} milestone={milestoneOf(task)} onOpen={onOpen} />
          ))}
        </ul>
      </SortableContext>
      {creating ? (
        <form className="board-create" onSubmit={submit}>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Escape') {
                setCreating(false)
                setTitle('')
              }
            }}
            onBlur={() => {
              if (!title.trim()) setCreating(false)
            }}
            placeholder="Título da tarefa (Enter para criar)"
            aria-label={`Título da nova tarefa em ${BOARD_LABELS[status]}`}
            maxLength={300}
            disabled={busy}
            autoFocus
          />
          {error && <p className="error small">{error}</p>}
        </form>
      ) : (
        <button type="button" className="board-add" onClick={() => setCreating(true)}>+ Criar</button>
      )}
    </section>
  )
}
