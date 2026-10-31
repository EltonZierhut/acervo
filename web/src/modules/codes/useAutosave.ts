import { useCallback, useEffect, useRef, useState } from 'react'
import { ApiError } from '../../core/api'
import { codesApi } from './api'
import type { Snippet, SnippetInput } from './types'

export type SaveState = 'idle' | 'pending' | 'saving' | 'saved' | 'error' | 'invalid'

const SAVE_DELAY = 800
const RETRY_DELAY = 5000
const MAX_CONTENT_BYTES = 1024 * 1024

const draftKey = (id: number | null) => `acervo:note-draft:${id ?? 'new'}`

// O rascunho só existe enquanto o salvamento falha, para sobreviver ao login após a sessão expirar.
export function readDraft(id: number | null): SnippetInput | null {
  try {
    const raw = sessionStorage.getItem(draftKey(id))
    return raw ? (JSON.parse(raw) as SnippetInput) : null
  } catch {
    return null
  }
}

export function clearDraft(id: number | null) {
  try {
    sessionStorage.removeItem(draftKey(id))
  } catch {
    // Sem acesso ao armazenamento não há rascunho para apagar.
  }
}

function writeDraft(id: number | null, form: SnippetInput) {
  try {
    sessionStorage.setItem(draftKey(id), JSON.stringify(form))
  } catch {
    // O texto continua na tela e o aviso de "não salvo" segue valendo.
  }
}

function validate(form: SnippetInput): string | null {
  if (!form.content.trim()) return 'O conteúdo está vazio. A última versão salva foi mantida.'
  if (new TextEncoder().encode(form.content).length > MAX_CONTENT_BYTES) {
    return 'O conteúdo passa do limite de 1 MB e não foi salvo.'
  }
  return null
}

interface Options {
  id: number | null
  initial: SnippetInput
  onSaved: (note: Snippet) => void
}

// Salva a versão mais recente, com um envio por vez. A resposta nunca altera o texto da tela.
export function useAutosave({ id, initial, onSaved }: Options) {
  const [form, setFormState] = useState(initial)
  const [state, setStateValue] = useState<SaveState>(id ? 'saved' : 'idle')
  const [message, setMessage] = useState<string | null>(null)

  const stateRef = useRef<SaveState>(state)
  const formRef = useRef(initial)
  const savedRef = useRef(JSON.stringify(initial))
  const idRef = useRef(id)
  const runningRef = useRef<Promise<void> | null>(null)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const retryRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const onSavedRef = useRef(onSaved)
  useEffect(() => {
    onSavedRef.current = onSaved
  })

  const setState = useCallback((next: SaveState) => {
    stateRef.current = next
    setStateValue(next)
  }, [])

  const clearTimers = useCallback(() => {
    if (timerRef.current) clearTimeout(timerRef.current)
    if (retryRef.current) clearTimeout(retryRef.current)
    timerRef.current = retryRef.current = null
  }, [])

  const send = useCallback((): Promise<void> => {
    runningRef.current ??= (async () => {
      for (;;) {
        const snapshot = formRef.current
        const serialized = JSON.stringify(snapshot)
        if (serialized === savedRef.current) {
          setState(idRef.current ? 'saved' : 'idle')
          setMessage(null)
          return
        }

        const invalid = validate(snapshot)
        if (invalid) {
          const untouched = !idRef.current && !snapshot.content.trim() && !snapshot.title.trim()
          setState(untouched ? 'idle' : 'invalid')
          setMessage(untouched ? null : invalid)
          return
        }

        setState('saving')
        try {
          const note = idRef.current
            ? await codesApi.updateSnippet(idRef.current, snapshot)
            : await codesApi.createSnippet(snapshot)
          clearDraft(idRef.current)
          idRef.current = note.id
          savedRef.current = serialized
          setMessage(null)
          onSavedRef.current(note)
        } catch (err) {
          if (err instanceof ApiError && err.status === 422) {
            setState('invalid')
            setMessage(err.errors.join(', '))
            return
          }
          writeDraft(idRef.current, formRef.current)
          setState('error')
          setMessage(null)
          retryRef.current = setTimeout(() => void send(), RETRY_DELAY)
          return
        }
      }
    })().finally(() => {
      runningRef.current = null
    })
    return runningRef.current
  }, [setState])

  const setForm = useCallback(
    (next: SnippetInput, immediate = false) => {
      formRef.current = next
      setFormState(next)
      clearTimers()
      setState('pending')
      timerRef.current = setTimeout(() => void send(), immediate ? 0 : SAVE_DELAY)
    },
    [clearTimers, send, setState],
  )

  // Só o conteúdo em branco pode ser abandonado sem aviso: a versão anterior continua salva.
  const hasUnsaved = useCallback(() => {
    if (JSON.stringify(formRef.current) === savedRef.current) return false
    return Boolean(formRef.current.content.trim())
  }, [])

  const flush = useCallback(async () => {
    clearTimers()
    await send()
    if (runningRef.current) await runningRef.current
    return !hasUnsaved()
  }, [clearTimers, hasUnsaved, send])

  // Descarta o que não foi salvo; usado quando o usuário decide sair mesmo assim.
  const abandon = useCallback(() => {
    clearTimers()
    clearDraft(idRef.current)
    formRef.current = JSON.parse(savedRef.current) as SnippetInput
  }, [clearTimers])

  const noteId = useCallback(() => idRef.current, [])

  // Sair da nota também salva, mesmo antes de a espera terminar.
  useEffect(
    () => () => {
      clearTimers()
      if (hasUnsaved()) void send()
    },
    [clearTimers, hasUnsaved, send],
  )

  return { form, state, message, setForm, flush, abandon, hasUnsaved, noteId }
}
