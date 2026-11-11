// Espelha specs/010-mentoring-module/contracts/mentoring-api.md.
export type MentorshipStatus = 'active' | 'paused' | 'finished'
export type GoalStatus = 'not_started' | 'in_progress' | 'achieved' | 'dropped'

export interface Counts {
  total: number
  done: number
}

export interface Mentorship {
  id: number
  mentor_name: string
  topic: string | null
  description: string | null
  started_on: string
  ended_on: string | null
  cadence: string | null
  status: MentorshipStatus
  created_at: string
  updated_at: string
  summary: { goals_open: number; goals_achieved: number; action_items_open: number; last_meeting_on: string | null }
}

export interface MentorshipInput {
  mentor_name: string
  topic?: string
  description?: string
  started_on?: string
  ended_on?: string
  cadence?: string
  status?: MentorshipStatus
}

export interface Question {
  id: number
  mentorship_id: number
  position: number
  prompt: string
  answer: string | null
  answered: boolean
  updated_at: string
}

export interface Goal {
  id: number
  mentorship_id: number
  title: string
  success_criteria: string | null
  description: string | null
  target_on: string | null
  status: GoalStatus
  progress: number
  overdue: boolean
  action_items: Counts
  created_at: string
  updated_at: string
}

export interface GoalInput {
  title?: string
  success_criteria?: string
  description?: string
  target_on?: string
  status?: GoalStatus
  progress?: number
}

export interface Meeting {
  id: number
  mentorship_id: number
  mentor_name: string
  held_on: string
  agenda: string | null
  notes: string | null
  takeaways: string | null
  rating: number | null
  tags: string[]
  action_items: Counts
  created_at: string
  updated_at: string
}

export interface MeetingInput {
  held_on?: string
  agenda?: string
  notes?: string
  takeaways?: string
  rating?: number | null
  tags?: string
}

export interface ActionItem {
  id: number
  mentorship_id: number
  meeting_id: number | null
  goal_id: number | null
  goal_title: string | null
  meeting_held_on: string | null
  title: string
  due_on: string | null
  completed_at: string | null
  done: boolean
  overdue: boolean
  created_at: string
  updated_at: string
}

export interface ActionItemInput {
  title?: string
  due_on?: string | null
  meeting_id?: number | null
  goal_id?: number | null
  done?: boolean
}

export interface Competency {
  id: number
  mentorship_id: number
  name: string
  position: number
}

export interface CompetencyEvolution extends Competency {
  ratings: { rated_on: string; score: number; comment: string | null }[]
  first: number | null
  last: number | null
  delta: number | null
}

export interface Assessments {
  dates: string[]
  competencies: CompetencyEvolution[]
}

export interface RatingInput {
  competency_id: number
  score: number | null
  comment?: string
}

export interface Overview {
  questions: { total: number; answered: number }
  goals: { total: number; achieved: number; average_progress: number | null }
  action_items: { total: number; done: number; overdue: number; next: ActionItem[] }
  meetings: {
    held: number
    last_held_on: string | null
    days_since_last: number | null
    next_on: string | null
    average_rating: number | null
  }
  competencies: { total: number; assessments: number; average_delta: number | null }
}

export interface Paginated<T> {
  data: T[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}
