import { api } from '../../core/api'
import type {
  Context, ContextInput, ExecutorStatusInfo, Initiative, InitiativeInput, InitiativeSummary, Milestone,
  MilestoneInput, Paginated, Run, Task, TaskImage, TaskInput, TaskLink, TaskList,
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

  listImages: (taskId: number) => api.get<TaskImage[]>(`${base}/tasks/${taskId}/task_images`),
  uploadImage: (taskId: number, file: File) =>
    api.upload<TaskImage>(`${base}/tasks/${taskId}/task_images`, file, { filename: file.name }),
  deleteImage: (id: number) => api.delete(`${base}/task_images/${id}`),

  listLinks: (taskId: number) => api.get<TaskLink[]>(`${base}/tasks/${taskId}/task_links`),
  createLink: (taskId: number, task_link: { url: string; title?: string }) =>
    api.post<TaskLink>(`${base}/tasks/${taskId}/task_links`, { task_link }),
  deleteLink: (id: number) => api.delete(`${base}/task_links/${id}`),

  verifyRepository: (id: number) => api.post<Initiative>(`${base}/initiatives/${id}/verify_repository`, {}),
  executorStatus: () => api.get<ExecutorStatusInfo>(`${base}/executor_status`),

  listTaskRuns: (taskId: number) => api.get<Run[]>(`${base}/tasks/${taskId}/runs`),
  enqueueTask: (taskId: number) => api.post<Run>(`${base}/tasks/${taskId}/runs`, {}),
  listRuns: (filters: { q?: string; status?: string; page?: number }) =>
    api.get<Paginated<Run>>(`${base}/runs`, { ...filters }),
  cancelRun: (id: number) => api.post<Run>(`${base}/runs/${id}/cancel`, {}),
  answerRun: (id: number, answers: { question_id: number; answer: string }[]) =>
    api.post<Run>(`${base}/runs/${id}/answers`, { answers }),
}
