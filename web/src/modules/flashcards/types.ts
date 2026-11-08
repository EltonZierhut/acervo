// Espelha specs/009-flashcards-module/contracts/flashcards-api.md.
export type CardState = 'new' | 'learning' | 'review' | 'relearning'
export type NoteType = 'basic' | 'basic_reversed'
export type Rating = 1 | 2 | 3 | 4

export interface DueCounts {
  new: number
  learning: number
  review: number
}

export interface Deck {
  id: number
  name: string
  description: string | null
  new_per_day: number
  reviews_per_day: number
  card_count: number
  due: DueCounts
  created_at: string
  updated_at: string
}

export interface DeckInput {
  name?: string
  description?: string
  new_per_day?: number
  reviews_per_day?: number
}

export interface Card {
  id: number
  ordinal: 0 | 1
  state: CardState
  due_at: string | null
  interval_days: number
  ease: number
  reps: number
  lapses: number
}

export interface Note {
  id: number
  deck_id: number
  note_type: NoteType
  front: string
  back: string
  tags: string[]
  suspended: boolean
  cards: Card[]
  created_at: string
  updated_at: string
}

export interface NoteInput {
  note_type?: NoteType
  front?: string
  back?: string
  tags?: string // separadas por vírgula
  deck_id?: number
  suspended?: boolean
}

export interface StudyCard {
  id: number
  note_id: number
  ordinal: 0 | 1
  state: CardState
  question: string
  answer: string
  tags: string[]
  intervals: Record<'1' | '2' | '3' | '4', string>
}

export interface Study {
  deck: { id: number; name: string }
  counts: DueCounts
  card: StudyCard | null
  next_due_at: string | null
  due_tomorrow: number
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}
