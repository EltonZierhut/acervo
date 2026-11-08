import { api } from '../../core/api'
import type { Deck, DeckInput, Note, NoteInput, Paginated, Rating, Study } from './types'

const base = '/flashcards'

export const flashcardsApi = {
  listDecks: () => api.get<{ data: Deck[] }>(`${base}/decks`).then((r) => r.data),
  getDeck: (id: number) => api.get<Deck>(`${base}/decks/${id}`),
  createDeck: (deck: DeckInput) => api.post<Deck>(`${base}/decks`, { deck }),
  updateDeck: (id: number, deck: DeckInput) => api.patch<Deck>(`${base}/decks/${id}`, { deck }),
  deleteDeck: (id: number) => api.delete(`${base}/decks/${id}`),

  listNotes: (deckId: number, params: { q?: string; tag?: string; page?: number }) =>
    api.get<Paginated<Note>>(`${base}/decks/${deckId}/notes`, params),
  getNote: (id: number) => api.get<Note>(`${base}/notes/${id}`),
  createNote: (deckId: number, note: NoteInput) => api.post<Note>(`${base}/decks/${deckId}/notes`, { note }),
  updateNote: (id: number, note: NoteInput) => api.patch<Note>(`${base}/notes/${id}`, { note }),
  resetNote: (id: number) => api.post<Note>(`${base}/notes/${id}/reset`, {}),
  deleteNote: (id: number) => api.delete(`${base}/notes/${id}`),

  study: (deckId: number) => api.get<Study>(`${base}/decks/${deckId}/study`),
  review: (cardId: number, rating: Rating, durationMs: number) =>
    api.post<Study>(`${base}/cards/${cardId}/review`, { rating, duration_ms: durationMs }),
}

export const STATE_LABELS = { new: 'Novo', learning: 'Aprendendo', review: 'Revisão', relearning: 'Reaprendendo' } as const

export const RATING_LABELS = { 1: 'Errei', 2: 'Difícil', 3: 'Bom', 4: 'Fácil' } as const

export function formatTime(value: string) {
  return new Date(value).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

export function formatDate(value: string) {
  return new Date(value).toLocaleDateString('pt-BR')
}
