export interface SnippetSummary {
  id: number
  title: string | null
  display_title: string
  language: string | null
  tags: string[]
  created_at: string
  updated_at: string
}

export interface Snippet extends SnippetSummary {
  content: string
  description: string | null
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}

export interface SnippetInput {
  title: string
  description: string
  language: string
  content: string
  tags: string
}
