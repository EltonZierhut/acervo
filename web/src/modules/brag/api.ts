import { api } from '../../core/api'
import type { BragEntry, BragEntryInput, Paginated } from './types'

const base = '/brag'

export const bragApi = {
  listEntries: (params: { q?: string; category?: string; tag?: string; year?: string; page?: number }) =>
    api.get<Paginated<BragEntry>>(`${base}/entries`, params),
  getEntry: (id: number) => api.get<BragEntry>(`${base}/entries/${id}`),
  createEntry: (entry: BragEntryInput) => api.post<BragEntry>(`${base}/entries`, { entry }),
  updateEntry: (id: number, entry: BragEntryInput) => api.patch<BragEntry>(`${base}/entries/${id}`, { entry }),
  deleteEntry: (id: number) => api.delete(`${base}/entries/${id}`),
}

export const CATEGORY_SUGGESTIONS = ['Entrega', 'Liderança', 'Mentoria', 'Aprendizado', 'Melhoria', 'Reconhecimento']

// Data local de hoje no formato AAAA-MM-DD (não usa UTC, que viraria o dia à noite).
export function today() {
  const now = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
}

export function formatDate(value: string) {
  const [year, month, day] = value.slice(0, 10).split('-').map(Number)
  return new Date(year, month - 1, day).toLocaleDateString('pt-BR')
}
