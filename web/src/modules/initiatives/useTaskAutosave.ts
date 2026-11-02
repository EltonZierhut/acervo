import { useCallback, useEffect, useRef, useState } from 'react'
import { ApiError } from '../../core/api'
import { initiativesApi } from './api'
import type { Task, TaskInput } from './types'

export type SaveState = 'idle' | 'pending' | 'saving' | 'saved' | 'error' | 'invalid'

export type TaskForm = Required<Pick<TaskInput, 'title' | 'description' | 'status' | 'priority' | 'due_on' | 'milestone_id'>>

const SAVE_DELAY = 800
const RETRY_DELAY = 5000

export function toForm(task: Task): TaskForm {
  return {
    title: task.title,
    description: task.description ?? '',
    status: task.status,
    priority: task.priority,
    due_on: task.due_on,
    milestone_id: task.milestone_id,
  }
}

// Só os campos que mudaram desde o último salvamento seguem para a API.
function changes(form: TaskForm, saved: TaskForm): TaskInput {
  const patch: Record<string, unknown> = {}
  for (const key of Object.keys(form) as (keyof TaskForm)[]) {
    if (form[key] !== saved[key]) patch[key] = form[key]
  }
  return patch as TaskInput
}

// Salvamento automático da tarefa: um envio por vez, sempre da versão mais recente do formulário.
// A resposta nunca altera o que está na tela.
export function useTaskAutosave(taskId: number, initial: TaskForm, onSaved: (task: Task) => void) {
  const [form, setFormState] = useState(initial)
  const [state, setStateValue] = useState<SaveState>('saved')
  const [message, setMessage] = useState<string | null>(null)

  const formRef = useRef(initial)
  const savedRef = useRef(initial)
  const runningRef = useRef<Promise<void> | null>(null)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const retryRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const onSavedRef = useRef(onSaved)
  useEffect(() => {
    onSavedRef.current = onSaved
  })

  const clearTimers = useCallback(() => {
    if (timerRef.current) clearTimeout(timerRef.current)
    if (retryRef.current) clearTimeout(retryRef.current)
    timerRef.current = retryRef.current = null
  }, [])

  const send = useCallback((): Promise<void> => {
    runningRef.current ??= (async () => {
      for (;;) {
        const snapshot = formRef.current
        const patch = changes(snapshot, savedRef.current)
        if (Object.keys(patch).length === 0) {
          setStateValue('saved')
          setMessage(null)
          return
        }
        if (!snapshot.title.trim()) {
          setStateValue('invalid')
          setMessage('O título não pode ficar vazio. A última versão salva foi mantida.')
          return
        }

        setStateValue('saving')
        try {
          const task = await initiativesApi.updateTask(taskId, patch)
          savedRef.current = { ...savedRef.current, ...snapshot }
          setMessage(null)
          onSavedRef.current(task)
        } catch (err) {
          if (err instanceof ApiError && err.status === 422) {
            setStateValue('invalid')
            setMessage(err.errors.join(', '))
            return
          }
          setStateValue('error')
          setMessage(null)
          retryRef.current = setTimeout(() => void send(), RETRY_DELAY)
          return
        }
      }
    })().finally(() => {
      runningRef.current = null
    })
    return runningRef.current
  }, [taskId])

  const setForm = useCallback(
    (patch: Partial<TaskForm>, immediate = false) => {
      formRef.current = { ...formRef.current, ...patch }
      setFormState(formRef.current)
      clearTimers()
      setStateValue('pending')
      timerRef.current = setTimeout(() => void send(), immediate ? 0 : SAVE_DELAY)
    },
    [clearTimers, send],
  )

  const hasUnsaved = useCallback(() => Object.keys(changes(formRef.current, savedRef.current)).length > 0, [])

  // Salva já e diz se não sobrou nada pendente.
  const flush = useCallback(async () => {
    clearTimers()
    await send()
    if (runningRef.current) await runningRef.current
    return !hasUnsaved()
  }, [clearTimers, hasUnsaved, send])

  // O usuário decidiu sair sem salvar.
  const abandon = useCallback(() => {
    clearTimers()
    formRef.current = savedRef.current
  }, [clearTimers])

  useEffect(
    () => () => {
      clearTimers()
      if (hasUnsaved()) void send()
    },
    [clearTimers, hasUnsaved, send],
  )

  return { form, state, message, setForm, flush, abandon, hasUnsaved }
}
