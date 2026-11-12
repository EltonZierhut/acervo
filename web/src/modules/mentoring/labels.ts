import type { GoalStatus, MentorshipStatus } from './types'

export const MENTORSHIP_STATUS: Record<MentorshipStatus, string> = {
  active: 'Ativa',
  paused: 'Pausada',
  finished: 'Encerrada',
}

export const GOAL_STATUS: Record<GoalStatus, string> = {
  not_started: 'Não iniciado',
  in_progress: 'Em andamento',
  achieved: 'Alcançado',
  dropped: 'Abandonado',
}

export const COMPETENCY_SUGGESTIONS = [
  'Comunicação', 'Liderança de pessoas', 'Visão estratégica', 'Influência', 'Tomada de decisão',
  'Gestão do tempo', 'Feedback', 'Delegação', 'Conhecimento técnico', 'Inteligência emocional',
]

// Data local de hoje no formato AAAA-MM-DD (não usa UTC, que viraria o dia à noite).
export function today() {
  const now = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
}

export function formatDate(value: string | null | undefined) {
  if (!value) return ''
  const [year, month, day] = value.slice(0, 10).split('-').map(Number)
  return new Date(year, month - 1, day).toLocaleDateString('pt-BR')
}

export function isFuture(value: string) {
  return value.slice(0, 10) > today()
}

export function signed(value: number) {
  const text = value.toLocaleString('pt-BR', { maximumFractionDigits: 1 })
  return value > 0 ? `+${text}` : text
}

export function errorMessage(err: unknown, fallback = 'Não foi possível salvar') {
  return err instanceof Error ? err.message : fallback
}
