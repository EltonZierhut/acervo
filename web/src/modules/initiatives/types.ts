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

export type RepositoryStatus = 'unverified' | 'valid' | 'invalid'

export interface Initiative extends InitiativeSummary {
  description: string | null
  sections: Section[]
  github_repository: string | null
  repository_status: RepositoryStatus
  repository_error: string | null
  repository_checked_at: string | null
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
  github_repository: string
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
  images_count: number
  links_count: number
  latest_run: { id: number; status: RunStatus; pull_request_url: string | null } | null
  created_at: string
  updated_at: string
}

export type RunStatus = 'queued' | 'running' | 'waiting' | 'pr_open' | 'no_changes' | 'failed' | 'canceled'

export interface RunQuestion {
  id: number
  body: string
  answer: string | null
  answered_at: string | null
}

export interface Run {
  id: number
  task_id: number
  task_title: string
  initiative_id: number
  initiative_name: string
  repository: string
  status: RunStatus
  enqueued_at: string
  started_at: string | null
  finished_at: string | null
  failure_kind: string | null
  failure_reason: string | null
  summary: string | null
  pull_request_url: string | null
  questions: RunQuestion[]
}

export interface TaskImage {
  id: number
  filename: string
  content_type: string
  byte_size: number
  url: string
}

export interface TaskLink {
  id: number
  url: string
  title: string | null
}

export interface ExecutorStatusInfo {
  configured: boolean
  available: boolean
  last_seen_at: string | null
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
