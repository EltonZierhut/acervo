import { lazy, Component, Suspense, useCallback, useEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import { useBlocker } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { initiativesApi } from '../api'
import { BOARD_LABELS, entries, formatDateTime, PRIORITY_LABELS } from '../labels'
import type { Milestone, Task } from '../types'
import { toForm, useTaskAutosave } from '../useTaskAutosave'
import type { SaveState } from '../useTaskAutosave'
import { TaskImages } from './TaskImages'
import { TaskLinks } from './TaskLinks'
import { TaskRunPanel } from './TaskRunPanel'

// O editor (Tiptap) só é baixado quando um modal abre.
const RichTextEditor = lazy(() => import('./RichTextEditor'))

// Se o editor não puder ser baixado (por exemplo, depois de um deploy), o resto da tarefa continua na tela.
class EditorBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false }

  static getDerivedStateFromError() {
    return { failed: true }
  }

  render() {
    if (this.state.failed) return <p className="error">Não foi possível carregar o editor. Recarregue a página.</p>
    return this.props.children
  }
}

const SAVE_LABELS: Record<SaveState, string> = {
  idle: '',
  pending: 'Salvando…',
  saving: 'Salvando…',
  saved: 'Salvo',
  error: 'Não salvo. Tentando de novo…',
  invalid: 'Não salvo',
}

interface Props {
  initiativeId: number
  number: number
  repository: string | null
  milestones: Milestone[] | null
  onClose: () => void
  // Algo mudou e o quadro precisa recarregar.
  onChanged: () => void
}

// Carrega a tarefa pelo número (o do endereço) e mostra o modal.
export function TaskModal(props: Props) {
  const { initiativeId, number, onClose } = props
  const [task, setTask] = useState<Task | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    initiativesApi
      .listTasks(initiativeId, { number })
      .then((result) => {
        if (!active) return
        if (result.data[0]) setTask(result.data[0])
        else setError('Tarefa não encontrada.')
      })
      .catch((err: Error) => active && setError(err.message))
    return () => {
      active = false
    }
  }, [initiativeId, number])

  if (task) return <TaskDialog {...props} task={task} />
  return (
    <Dialog onRequestClose={onClose} label="Tarefa">
      {error ? (
        <div className="empty">
          <p>{error}</p>
          <button type="button" onClick={onClose}>Fechar</button>
        </div>
      ) : (
        <p className="muted">Carregando…</p>
      )}
    </Dialog>
  )
}

interface DialogProps {
  label: string
  onRequestClose: () => void
  children: ReactNode
}

// Janela por cima do quadro: fecha com Esc e clicando fora, e prende a rolagem da página.
function Dialog({ label, onRequestClose, children }: DialogProps) {
  const ref = useRef<HTMLDivElement>(null)
  const pressedOnBackdrop = useRef(false)
  const closeRef = useRef(onRequestClose)
  useEffect(() => {
    closeRef.current = onRequestClose
  })

  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    ref.current?.focus()
    document.body.classList.add('modal-open')
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== 'Escape' || event.defaultPrevented || event.isComposing) return
      // Esc dentro de um seletor ou de um campo de data só fecha o próprio controle.
      const target = event.target as HTMLElement
      if (target.tagName === 'SELECT' || (target as HTMLInputElement).type === 'date') return
      closeRef.current()
    }
    window.addEventListener('keydown', onKey)
    return () => {
      window.removeEventListener('keydown', onKey)
      document.body.classList.remove('modal-open')
      previous?.focus?.()
    }
  }, [])

  return (
    <div
      className="modal-backdrop"
      onMouseDown={(e) => {
        pressedOnBackdrop.current = e.target === e.currentTarget
      }}
      onMouseUp={(e) => {
        if (pressedOnBackdrop.current && e.target === e.currentTarget) closeRef.current()
        pressedOnBackdrop.current = false
      }}
    >
      <div className="modal" role="dialog" aria-modal="true" aria-label={label} tabIndex={-1} ref={ref}>
        {children}
      </div>
    </div>
  )
}

function TaskDialog({ task: loaded, repository, milestones, onClose, onChanged }: Props & { task: Task }) {
  const [task, setTask] = useState(loaded)
  const [initial] = useState(() => toForm(loaded))
  const changed = useRef(false)
  const [closeFailed, setCloseFailed] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const onSaved = useCallback((saved: Task) => {
    changed.current = true
    setTask((current) => ({ ...current, ...saved }))
  }, [])
  const { form, state, message, setForm, flush, abandon, hasUnsaved } = useTaskAutosave(loaded.id, initial, onSaved)

  // Ao fechar, o quadro recarrega se algo mudou.
  const finish = useCallback(() => {
    if (changed.current) onChanged()
    onClose()
  }, [onChanged, onClose])

  // Fechar tenta salvar; só avisa se não conseguir.
  const requestClose = useCallback(async () => {
    if (await flush()) finish()
    else setCloseFailed(true)
  }, [finish, flush])

  const discardAndClose = () => {
    abandon()
    finish()
  }

  // Botão voltar do navegador (ou qualquer troca de endereço) com alteração pendente.
  const blocker = useBlocker(() => hasUnsaved())
  useEffect(() => {
    if (blocker.state !== 'blocked') return
    void flush().then((ok) => {
      if (ok) blocker.proceed()
      else setCloseFailed(true)
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [blocker.state])

  useEffect(() => {
    const warn = (event: BeforeUnloadEvent) => {
      if (!hasUnsaved()) return
      void flush()
      event.preventDefault()
    }
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [flush, hasUnsaved])

  const remove = async () => {
    if (!window.confirm(`Apagar a tarefa "${task.title}"?`)) return
    try {
      await initiativesApi.deleteTask(task.id)
      abandon()
      changed.current = true
      finish()
    } catch (err) {
      setDeleteError(err instanceof ApiError ? err.message : 'Não foi possível apagar a tarefa.')
    }
  }

  const failed = state === 'error' || state === 'invalid'
  return (
    <Dialog label={`Tarefa #${task.number}`} onRequestClose={() => void requestClose()}>
      <header className="modal-header">
        <span className="muted">#{task.number}</span>
        <span className={failed ? 'save-status error' : 'save-status muted'} role="status">
          {SAVE_LABELS[state]}
        </span>
        <button type="button" className="modal-close" aria-label="Fechar" onClick={() => void requestClose()}>×</button>
      </header>

      {closeFailed && (
        <div className="notice note-banner" role="alert">
          <span>Não foi possível salvar as alterações.</span>
          <button type="button" onClick={() => { setCloseFailed(false); if (blocker.state === 'blocked') blocker.reset() }}>
            Continuar editando
          </button>
          <button type="button" className="danger" onClick={() => { discardAndClose(); if (blocker.state === 'blocked') blocker.proceed() }}>
            Fechar sem salvar
          </button>
        </div>
      )}
      {message && <p className="error small">{message}</p>}

      <div className="modal-body">
        <div className="modal-main">
          <input
            className="modal-title"
            value={form.title}
            onChange={(e) => setForm({ title: e.target.value })}
            aria-label="Título"
            maxLength={300}
          />
          <div className="field">
            <span className="field-label">Descrição</span>
            <EditorBoundary>
              <Suspense fallback={<p className="muted">Carregando editor…</p>}>
                <RichTextEditor value={form.description} onChange={(html) => setForm({ description: html })} />
              </Suspense>
            </EditorBoundary>
          </div>
          <div className="task-extras">
            <TaskImages taskId={task.id} onChanged={() => { changed.current = true }} />
            <TaskLinks taskId={task.id} onChanged={() => { changed.current = true }} />
            <TaskRunPanel task={task} repository={repository} onChanged={() => { changed.current = true }} />
          </div>
        </div>

        <aside className="modal-side">
          <label>
            Status
            <select value={form.status} onChange={(e) => setForm({ status: e.target.value as Task['status'] }, true)}>
              {entries(BOARD_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>
          <label>
            Prioridade
            <select value={form.priority} onChange={(e) => setForm({ priority: e.target.value as Task['priority'] }, true)}>
              {entries(PRIORITY_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>
          <label>
            Prazo
            <input type="date" value={form.due_on ?? ''} onChange={(e) => setForm({ due_on: e.target.value || null }, true)} />
          </label>
          {milestones && (
            <label>
              Marco
              <select
                value={form.milestone_id ?? ''}
                onChange={(e) => setForm({ milestone_id: e.target.value ? Number(e.target.value) : null }, true)}
              >
                <option value="">Sem marco</option>
                {milestones.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
              </select>
            </label>
          )}
          <dl className="modal-dates small muted">
            <dt>Criada em</dt>
            <dd>{formatDateTime(task.created_at)}</dd>
            <dt>Alterada em</dt>
            <dd>{formatDateTime(task.updated_at)}</dd>
            {task.completed_at && (
              <>
                <dt>Concluída em</dt>
                <dd>{formatDateTime(task.completed_at)}</dd>
              </>
            )}
          </dl>
          {deleteError && <p className="error small">{deleteError}</p>}
          <button type="button" className="btn danger" onClick={() => void remove()}>Apagar</button>
        </aside>
      </div>
    </Dialog>
  )
}
