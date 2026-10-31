import { api } from '../../core/api'
import type {
  Context, ContextInput, Initiative, InitiativeInput, InitiativeSummary, Milestone, MilestoneInput,
  Paginated, Task, TaskInput, TaskList,
} from './types'

const base = '/initiatives'

export interface InitiativeFilters {
  q?: string
  status?: string
  context_id?: string
  page?: number
}

export const initiativesApi = {
  listContexts: () => api.get<Context[]>(`${base}/contexts`),
  createContext: (context: ContextInput) => api.post<Context>(`${base}/contexts`, { context }),
  updateContext: (id: number, context: ContextInput) => api.patch<Context>(`${base}/contexts/${id}`, { context }),
  deleteContext: (id: number) => api.delete(`${base}/contexts/${id}`),

  listInitiatives: (filters: InitiativeFilters) =>
    api.get<Paginated<InitiativeSummary>>(`${base}/initiatives`, { ...filters }),
  getInitiative: (id: number) => api.get<Initiative>(`${base}/initiatives/${id}`),
  createInitiative: (initiative: InitiativeInput) =>
    api.post<Initiative>(`${base}/initiatives`, { initiative }),
  updateInitiative: (id: number, initiative: Partial<InitiativeInput>) =>
    api.patch<Initiative>(`${base}/initiatives/${id}`, { initiative }),
  deleteInitiative: (id: number) => api.delete(`${base}/initiatives/${id}`),

  listMilestones: (initiativeId: number) =>
    api.get<{ data: Milestone[] }>(`${base}/initiatives/${initiativeId}/milestones`).then((r) => r.data),
  createMilestone: (initiativeId: number, milestone: MilestoneInput) =>
    api.post<Milestone>(`${base}/initiatives/${initiativeId}/milestones`, { milestone }),
  updateMilestone: (id: number, milestone: MilestoneInput) =>
    api.patch<Milestone>(`${base}/milestones/${id}`, { milestone }),
  deleteMilestone: (id: number) => api.delete(`${base}/milestones/${id}`),

  listTasks: (initiativeId: number, filters: { q?: string; status?: string; milestone_id?: string }) =>
    api.get<TaskList>(`${base}/initiatives/${initiativeId}/tasks`, filters),
  createTask: (initiativeId: number, task: TaskInput) =>
    api.post<Task>(`${base}/initiatives/${initiativeId}/tasks`, { task }),
  updateTask: (id: number, task: TaskInput) => api.patch<Task>(`${base}/tasks/${id}`, { task }),
  deleteTask: (id: number) => api.delete(`${base}/tasks/${id}`),
}
