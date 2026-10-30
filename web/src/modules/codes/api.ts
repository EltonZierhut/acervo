import { api } from '../../core/api'
import type { Paginated, Project, ProjectInput, Snippet, SnippetInput } from './types'

const base = '/codes'

export const codesApi = {
  listSnippets: (params: { q?: string; language?: string; tag?: string; project_id?: number; page?: number }) =>
    api.get<Paginated<Snippet>>(`${base}/snippets`, params),
  getSnippet: (id: number) => api.get<Snippet>(`${base}/snippets/${id}`),
  createSnippet: (snippet: SnippetInput) => api.post<Snippet>(`${base}/snippets`, { snippet }),
  updateSnippet: (id: number, snippet: SnippetInput) => api.patch<Snippet>(`${base}/snippets/${id}`, { snippet }),
  deleteSnippet: (id: number) => api.delete(`${base}/snippets/${id}`),

  listProjects: (q?: string) => api.get<Project[]>(`${base}/projects`, { q }),
  getProject: (id: number) => api.get<Project>(`${base}/projects/${id}`),
  createProject: (project: ProjectInput) => api.post<Project>(`${base}/projects`, { project }),
  updateProject: (id: number, project: ProjectInput) => api.patch<Project>(`${base}/projects/${id}`, { project }),
  deleteProject: (id: number) => api.delete(`${base}/projects/${id}`),
}

export const LANGUAGES = [
  'bash', 'css', 'go', 'html', 'java', 'javascript', 'json', 'python',
  'ruby', 'rust', 'sql', 'typescript', 'yaml', 'outro',
]
