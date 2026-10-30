export interface ProjectRef {
  id: number
  name: string
}

export interface Project extends ProjectRef {
  description: string | null
  repository_url: string | null
  tags: string[]
  snippets_count?: number
  snippets?: Snippet[]
  created_at: string
  updated_at: string
}

export interface Snippet {
  id: number
  title: string
  description: string | null
  language: string | null
  content: string
  tags: string[]
  project_id: number | null
  project: ProjectRef | null
  created_at: string
  updated_at: string
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}

export type SnippetInput = Pick<Snippet, 'title' | 'description' | 'language' | 'content' | 'project_id'> & {
  tags: string
}

export type ProjectInput = Pick<Project, 'name' | 'description' | 'repository_url'> & { tags: string }
