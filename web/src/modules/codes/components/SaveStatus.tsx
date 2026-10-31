import type { SaveState } from '../useAutosave'

const LABELS: Record<SaveState, string> = {
  idle: '',
  pending: 'Salvando…',
  saving: 'Salvando…',
  saved: 'Salvo',
  error: 'Não salvo. Tentando de novo…',
  invalid: 'Não salvo',
}

export function SaveStatus({ state }: { state: SaveState }) {
  const failed = state === 'error' || state === 'invalid'
  return (
    <span className={failed ? 'save-status error' : 'save-status muted'} role="status">
      {LABELS[state]}
    </span>
  )
}
