import type { InitiativeStatus, Priority, RepositoryStatus, RunStatus, Section, TaskStatus } from './types'

export const STATUS_LABELS: Record<InitiativeStatus, string> = {
  active: 'Ativa',
  planned: 'Planejada',
  idea: 'Ideia',
  paused: 'Pausada',
  done: 'Encerrada',
}

export const PRIORITY_LABELS: Record<Priority, string> = { high: 'Alta', medium: 'Média', low: 'Baixa' }

export const TASK_STATUS_LABELS: Record<TaskStatus, string> = { doing: 'Fazendo', todo: 'A fazer', done: 'Concluídas' }
export const TASK_STATUS_OPTIONS: Record<TaskStatus, string> = { todo: 'A fazer', doing: 'Fazendo', done: 'Concluída' }

// Mesma ordem da API (Initiative::SECTIONS).
export const SECTION_LABELS: Record<Section, string> = { tasks: 'Tarefas', milestones: 'Marcos' }
export const SECTIONS = Object.keys(SECTION_LABELS) as Section[]

export const RUN_STATUS_LABELS: Record<RunStatus, string> = {
  queued: 'Na fila',
  running: 'Em execução',
  waiting: 'Aguardando resposta',
  pr_open: 'PR aberto',
  no_changes: 'Sem alterações',
  failed: 'Falhou',
  canceled: 'Cancelada',
}

export const REPOSITORY_STATUS_LABELS: Record<RepositoryStatus, string> = {
  unverified: 'Não verificado',
  valid: 'Acesso confirmado',
  invalid: 'Sem acesso',
}

export const ACTIVE_RUN_STATUSES: RunStatus[] = ['queued', 'running', 'waiting']

export const CONTEXT_COLORS = ['#2f6fed', '#7c3aed', '#0a7a3d', '#b35000', '#c93c3c', '#0e7490', '#a3356b', '#6b7380']

export function entries<K extends string>(labels: Record<K, string>) {
  return Object.entries(labels) as [K, string][]
}

// Datas de calendário chegam como "YYYY-MM-DD" e não devem mudar de dia com o fuso.
export function formatDate(value: string | null) {
  if (!value) return ''
  const [year, month, day] = value.slice(0, 10).split('-').map(Number)
  return new Date(year, month - 1, day).toLocaleDateString('pt-BR')
}

export function formatDateTime(value: string | null) {
  return value ? new Date(value).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' }) : ''
}

// "há 3 min", usado na fila.
export function timeAgo(value: string | null) {
  if (!value) return ''
  const minutes = Math.max(0, Math.round((Date.now() - new Date(value).getTime()) / 60000))
  if (minutes < 1) return 'agora'
  if (minutes < 60) return `há ${minutes} min`
  const hours = Math.round(minutes / 60)
  return hours < 24 ? `há ${hours} h` : `há ${Math.round(hours / 24)} d`
}

export function today() {
  const now = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
}

export function isOverdue(dueOn: string | null, finished: boolean) {
  return !finished && dueOn !== null && dueOn < today()
}
