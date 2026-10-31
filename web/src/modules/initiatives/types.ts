export type InitiativeStatus = 'idea' | 'planned' | 'active' | 'paused' | 'done'
export type Priority = 'low' | 'medium' | 'high'
export type TaskStatus = 'todo' | 'doing' | 'done'
export type Section = 'tasks' | 'milestones'

export interface Progress {
  done: number
  total: number
}

export interface Context {
  id: number
  name: string
  color: string
  initiatives_count: number
}

export interface ContextRef {
  id: number
  name: string
  color: string
}

export interface InitiativeSummary {
  id: number
  name: string
  status: InitiativeStatus
  priority: Priority
  starts_on: string | null
  due_on: string | null
  tags: string[]
  context: ContextRef | null
  progress: Progress
  created_at: string
  updated_at: string
}

export interface Initiative extends InitiativeSummary {
  description: string | null
  sections: Section[]
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}

export interface InitiativeInput {
  name: string
  description: string
  context_id: number | null
  status: InitiativeStatus
  priority: Priority
  starts_on: string | null
  due_on: string | null
  tags: string
  sections: Section[]
}

export interface Milestone {
  id: number
  initiative_id: number
  title: string
  description: string | null
  due_on: string | null
  completed_at: string | null
  progress: Progress
  created_at: string
  updated_at: string
}

export interface MilestoneInput {
  title?: string
  description?: string
  due_on?: string | null
  completed?: boolean
}

export interface Task {
  id: number
  initiative_id: number
  milestone_id: number | null
  title: string
  description: string | null
  status: TaskStatus
  priority: Priority
  due_on: string | null
  completed_at: string | null
  created_at: string
  updated_at: string
}

export interface TaskList {
  data: Task[]
  meta: { total: number; truncated: boolean }
}

export interface TaskInput {
  title?: string
  description?: string
  status?: TaskStatus
  priority?: Priority
  due_on?: string | null
  milestone_id?: number | null
}

export interface ContextInput {
  name?: string
  color?: string
}
