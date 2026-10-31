import { api } from '../../core/api'
import type { Paginated, Snippet, SnippetInput, SnippetSummary } from './types'

const base = '/codes'

export const codesApi = {
  listSnippets: (params: { q?: string; language?: string; tag?: string; page?: number }) =>
    api.get<Paginated<SnippetSummary>>(`${base}/snippets`, params),
  getSnippet: (id: number) => api.get<Snippet>(`${base}/snippets/${id}`),
  createSnippet: (snippet: SnippetInput) => api.post<Snippet>(`${base}/snippets`, { snippet }),
  updateSnippet: (id: number, snippet: SnippetInput) => api.patch<Snippet>(`${base}/snippets/${id}`, { snippet }),
  deleteSnippet: (id: number) => api.delete(`${base}/snippets/${id}`),
}

export const LANGUAGES = [
  'bash', 'css', 'go', 'html', 'java', 'javascript', 'json', 'python',
  'ruby', 'rust', 'sql', 'typescript', 'yaml',
]
