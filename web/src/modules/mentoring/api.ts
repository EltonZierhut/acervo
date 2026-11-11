import { api } from '../../core/api'
import type {
  ActionItem, ActionItemInput, Assessments, Competency, Goal, GoalInput, Meeting, MeetingInput, Mentorship,
  MentorshipInput, Overview, Paginated, Question, RatingInput,
} from './types'

const base = '/mentoring'
const of = (id: number) => `${base}/mentorships/${id}`

export const mentoringApi = {
  listMentorships: () => api.get<{ data: Mentorship[] }>(`${base}/mentorships`),
  getMentorship: (id: number) => api.get<Mentorship>(of(id)),
  createMentorship: (mentorship: MentorshipInput, useSuggestedQuestions: boolean) =>
    api.post<Mentorship>(`${base}/mentorships`, { mentorship, use_suggested_questions: useSuggestedQuestions }),
  updateMentorship: (id: number, mentorship: MentorshipInput) => api.patch<Mentorship>(of(id), { mentorship }),
  deleteMentorship: (id: number) => api.delete(of(id)),
  overview: (id: number) => api.get<Overview>(`${of(id)}/overview`),

  listQuestions: (id: number) => api.get<{ data: Question[] }>(`${of(id)}/questions`),
  createQuestion: (id: number, prompt: string) => api.post<Question>(`${of(id)}/questions`, { question: { prompt } }),
  updateQuestion: (id: number, question: { prompt?: string; answer?: string }) =>
    api.patch<Question>(`${base}/questions/${id}`, { question }),
  moveQuestion: (id: number, direction: 'up' | 'down') =>
    api.post<{ data: Question[] }>(`${base}/questions/${id}/move`, { direction }),
  deleteQuestion: (id: number) => api.delete(`${base}/questions/${id}`),

  listGoals: (id: number) => api.get<{ data: Goal[] }>(`${of(id)}/goals`),
  createGoal: (id: number, goal: GoalInput) => api.post<Goal>(`${of(id)}/goals`, { goal }),
  updateGoal: (id: number, goal: GoalInput) => api.patch<Goal>(`${base}/goals/${id}`, { goal }),
  deleteGoal: (id: number) => api.delete(`${base}/goals/${id}`),

  listMeetings: (id: number, params: { q?: string; page?: number }) =>
    api.get<Paginated<Meeting>>(`${of(id)}/meetings`, params),
  createMeeting: (id: number, meeting: MeetingInput = {}) => api.post<Meeting>(`${of(id)}/meetings`, { meeting }),
  getMeeting: (id: number) => api.get<Meeting>(`${base}/meetings/${id}`),
  updateMeeting: (id: number, meeting: MeetingInput) => api.patch<Meeting>(`${base}/meetings/${id}`, { meeting }),
  deleteMeeting: (id: number) => api.delete(`${base}/meetings/${id}`),

  listActionItems: (id: number, params: { meeting_id?: number; status?: 'open' | 'done' } = {}) =>
    api.get<{ data: ActionItem[] }>(`${of(id)}/action_items`, params),
  createActionItem: (id: number, action_item: ActionItemInput) =>
    api.post<ActionItem>(`${of(id)}/action_items`, { action_item }),
  updateActionItem: (id: number, action_item: ActionItemInput) =>
    api.patch<ActionItem>(`${base}/action_items/${id}`, { action_item }),
  deleteActionItem: (id: number) => api.delete(`${base}/action_items/${id}`),

  listCompetencies: (id: number) => api.get<{ data: Competency[] }>(`${of(id)}/competencies`),
  createCompetency: (id: number, name: string) => api.post<Competency>(`${of(id)}/competencies`, { competency: { name } }),
  updateCompetency: (id: number, name: string) => api.patch<Competency>(`${base}/competencies/${id}`, { competency: { name } }),
  deleteCompetency: (id: number) => api.delete(`${base}/competencies/${id}`),

  assessments: (id: number) => api.get<Assessments>(`${of(id)}/assessments`),
  saveAssessment: (id: number, rated_on: string, ratings: RatingInput[]) =>
    api.post<Assessments>(`${of(id)}/assessments`, { rated_on, ratings }),
  deleteAssessment: (id: number, ratedOn: string) => api.delete(`${of(id)}/assessments/${ratedOn}`),
}
