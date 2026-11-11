import type { Page, Route } from '@playwright/test'

// API simulada: respostas fixas, com textos longos de propósito para forçar quebras de linha.
const long = 'Um título bastante longo que precisa quebrar a linha sem estourar a largura da tela do celular'
const now = '2026-01-01T12:00:00Z'
const progress = { done: 1, total: 3 }
const context = { id: 1, name: 'Pessoal', color: '#2f6fed', initiatives_count: 1 }
const page1 = { page: 1, per_page: 20, total: 1, total_pages: 1 }

const snippet = {
  id: 1, title: long, display_title: long, language: 'javascript', tags: ['um', 'dois', 'tres'],
  created_at: now, updated_at: now,
  content: 'const x = 1\n' + 'const texto = "uma linha de código muito longa para testar a rolagem horizontal dentro do editor"\n'.repeat(20),
  description: 'Descrição da nota',
}
const bragEntry = {
  id: 1, title: long, achieved_on: '2026-01-01', description: '**Texto** em _Markdown_\n\n- item um\n- item dois', category: 'Entrega',
  tags: ['um', 'dois'], impact: 'Impacto', metrics: '-30%', evidence_links: ['https://exemplo.com/evidencia'], project: 'Acervo',
  created_at: now, updated_at: now,
}
const initiative = {
  id: 1, name: long, status: 'active', priority: 'high', starts_on: '2026-01-01', due_on: '2026-02-01',
  tags: ['a', 'b'], context: { id: 1, name: 'Pessoal', color: '#2f6fed' }, progress, created_at: now, updated_at: now,
  description: 'Descrição da iniciativa', sections: ['tasks', 'milestones'], github_repository: 'usuario/repositorio-com-nome-grande',
  repository_status: 'valid', repository_error: null, repository_checked_at: now,
}
const task = (id: number, status: string) => ({
  id, number: id, position: id, initiative_id: 1, milestone_id: 1, title: long, description: '<p>Texto</p>', status,
  priority: 'high', due_on: '2026-02-01', completed_at: null, images_count: 0, links_count: 0, latest_run: null,
  created_at: now, updated_at: now,
})
const milestone = {
  id: 1, initiative_id: 1, title: long, description: 'Descrição do marco', due_on: '2026-02-01', completed_at: null,
  progress, created_at: now, updated_at: now,
}
const run = {
  id: 1, task_id: 1, task_title: long, initiative_id: 1, initiative_name: long, repository: 'usuario/repositorio',
  status: 'waiting', enqueued_at: now, started_at: now, finished_at: null, failure_kind: null, failure_reason: null,
  summary: null, pull_request_url: null, questions: [{ id: 1, body: 'Pergunta?', answer: null, answered_at: null }],
}

const due = { new: 12, learning: 3, review: 140 }
const deck = {
  id: 1, name: long, description: 'Descrição do baralho', new_per_day: 20, reviews_per_day: 200, card_count: 1234, due,
  created_at: now, updated_at: now,
}
const flashcard = { id: 1, ordinal: 0, state: 'review', due_at: now, interval_days: 12, ease: 2500, reps: 5, lapses: 1 }
const flashcardNote = {
  id: 1, deck_id: 1, note_type: 'basic_reversed', front: long, back: '```\n' + 'x'.repeat(200) + '\n```', tags: ['tag-longa'],
  suspended: false, cards: [flashcard, { ...flashcard, id: 2, ordinal: 1, state: 'new' }], created_at: now, updated_at: now,
}
const study = {
  deck: { id: 1, name: long }, counts: due, next_due_at: null, due_tomorrow: 8,
  card: {
    id: 1, note_id: 1, ordinal: 0, state: 'review', question: long, answer: flashcardNote.back, tags: ['tag-longa'],
    intervals: { 1: '10 min', 2: '15 dias', 3: '1,2 mês', 4: '3,5 meses' },
  },
}

const mentorship = {
  id: 1, mentor_name: long, topic: long, description: 'Combinados **importantes**', started_on: '2026-01-01', ended_on: null,
  cadence: 'quinzenal, 1 h', status: 'active', created_at: now, updated_at: now,
  summary: { goals_open: 2, goals_achieved: 1, action_items_open: 3, last_meeting_on: '2026-01-10' },
}
const question = (id: number, answer: string | null) => ({
  id, mentorship_id: 1, position: id, prompt: long + '?', answer, answered: !!answer, updated_at: now,
})
const goal = {
  id: 1, mentorship_id: 1, title: long, success_criteria: 'Critério com `codigo_muito_longo_sem_espacos_para_quebrar_a_linha`',
  description: null, target_on: '2026-01-05', status: 'in_progress', progress: 40, overdue: true, action_items: progress,
  created_at: now, updated_at: now,
}
const actionItem = (id: number, done: boolean) => ({
  id, mentorship_id: 1, meeting_id: 1, goal_id: 1, goal_title: long, meeting_held_on: '2026-01-10', title: long, due_on: '2026-01-02',
  completed_at: done ? now : null, done, overdue: !done, created_at: now, updated_at: now,
})
const meeting = {
  id: 1, mentorship_id: 1, mentor_name: long, held_on: '2026-01-10', agenda: 'Pauta', notes: 'Anotações', takeaways: long,
  rating: 4, tags: ['carreira', 'tag-bastante-longa'], action_items: progress, created_at: now, updated_at: now,
}
const evolution = (id: number, scores: number[]) => ({
  id, mentorship_id: 1, name: long, position: id, first: scores[0], last: scores[scores.length - 1],
  delta: scores.length > 1 ? scores[scores.length - 1] - scores[0] : null,
  ratings: scores.map((score, i) => ({ rated_on: `2026-0${i + 1}-01`, score, comment: i === scores.length - 1 ? long : null })),
})
const assessments = {
  dates: ['2026-01-01', '2026-02-01', '2026-03-01'],
  competencies: [evolution(1, [2, 3, 4]), evolution(2, [3, 3, 2]), evolution(3, [])],
}
const overview = {
  questions: { total: 12, answered: 5 },
  goals: { total: 3, achieved: 1, average_progress: 47 },
  action_items: { total: 8, done: 5, overdue: 2, next: [actionItem(1, false), actionItem(2, false)] },
  meetings: { held: 4, last_held_on: '2026-01-10', days_since_last: 12, next_on: '2026-01-24', average_rating: 4.3 },
  competencies: { total: 3, assessments: 3, average_delta: 0.5 },
}

function respond(method: string, path: string): { status: number; body?: unknown } {
  if (path === '/session') return method === 'GET' ? { status: 200, body: { user: { id: 1, email_address: 'pessoa@exemplo.com' } } } : { status: 204 }
  if (path === '/codes/snippets') return { status: 200, body: { data: [snippet], meta: page1 } }
  if (path.startsWith('/codes/snippets/')) return { status: 200, body: snippet }
  if (path === '/brag/entries') return { status: 200, body: { data: [bragEntry], meta: page1 } }
  if (path.startsWith('/brag/entries/')) return { status: 200, body: bragEntry }
  if (path === '/flashcards/decks') return { status: 200, body: { data: [deck] } }
  if (/^\/flashcards\/decks\/\d+$/.test(path)) return { status: 200, body: deck }
  if (/^\/flashcards\/decks\/\d+\/notes$/.test(path)) return { status: 200, body: { data: [flashcardNote], meta: page1 } }
  if (/^\/flashcards\/decks\/\d+\/study$/.test(path)) return { status: 200, body: study }
  if (/^\/flashcards\/notes\/\d+$/.test(path)) return { status: 200, body: flashcardNote }
  if (path === '/initiatives/contexts') return { status: 200, body: [context] }
  if (path === '/mentoring/mentorships') return { status: 200, body: { data: [mentorship] } }
  if (/^\/mentoring\/mentorships\/\d+$/.test(path)) return { status: 200, body: mentorship }
  if (path.endsWith('/overview')) return { status: 200, body: overview }
  if (/^\/mentoring\/mentorships\/\d+\/questions$/.test(path)) return { status: 200, body: { data: [question(1, '**Resposta** longa ' + long), question(2, null)] } }
  if (/^\/mentoring\/mentorships\/\d+\/goals$/.test(path)) return { status: 200, body: { data: [goal, { ...goal, id: 2, status: 'achieved', progress: 100, overdue: false }] } }
  if (/^\/mentoring\/mentorships\/\d+\/meetings$/.test(path)) return { status: 200, body: { data: [meeting], meta: page1 } }
  if (/^\/mentoring\/meetings\/\d+$/.test(path)) return { status: 200, body: meeting }
  if (/^\/mentoring\/mentorships\/\d+\/action_items$/.test(path)) return { status: 200, body: { data: [actionItem(1, false), actionItem(2, true)] } }
  if (/^\/mentoring\/mentorships\/\d+\/assessments$/.test(path)) return { status: 200, body: assessments }
  if (path === '/initiatives/initiatives') return { status: 200, body: { data: [initiative], meta: page1 } }
  if (/^\/initiatives\/initiatives\/\d+$/.test(path)) return { status: 200, body: initiative }
  if (path.endsWith('/milestones')) return { status: 200, body: { data: [milestone] } }
  if (path.endsWith('/tasks')) {
    return { status: 200, body: { data: [task(1, 'todo'), task(2, 'doing'), task(3, 'done')], meta: { total: 3, truncated: false } } }
  }
  if (/\/tasks\/\d+$/.test(path)) return { status: 200, body: task(1, 'todo') }
  if (path.endsWith('/executor_status')) return { status: 200, body: { configured: true, available: true, last_seen_at: now } }
  if (path === '/initiatives/runs') return { status: 200, body: { data: [run], meta: page1 } }
  if (path.includes('/runs') || path.endsWith('/task_images') || path.endsWith('/task_links')) return { status: 200, body: [] }
  return { status: 404, body: { error: 'não simulado' } }
}

export async function mockApi(page: Page, options: { loggedIn?: boolean } = {}) {
  const loggedIn = options.loggedIn ?? true
  await page.route('**/api/v1/**', (route: Route) => {
    const request = route.request()
    const path = new URL(request.url()).pathname.replace('/api/v1', '')
    if (!loggedIn) return route.fulfill({ status: 401, json: { error: 'Não autenticado' } })
    const { status, body } = respond(request.method(), path)
    return route.fulfill(body === undefined ? { status } : { status, json: body })
  })
}
