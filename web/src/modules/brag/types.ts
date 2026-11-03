export interface BragEntry {
  id: number
  title: string
  achieved_on: string // AAAA-MM-DD
  description: string | null
  category: string | null
  tags: string[]
  impact: string | null
  metrics: string | null
  evidence_links: string[]
  project: string | null
  created_at: string
  updated_at: string
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}

// Só o título é necessário para o registro rápido; a data padrão é hoje.
export interface BragEntryInput {
  title: string
  achieved_on?: string
  description?: string
  category?: string
  tags?: string
  impact?: string
  metrics?: string
  evidence_links?: string // um endereço por linha
  project?: string
}
