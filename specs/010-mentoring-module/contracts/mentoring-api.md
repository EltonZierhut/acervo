# Contrato da API: Módulo Mentoria

Base: `/api/v1/mentoring`. Todas as rotas exigem login. Corpo em JSON; erros no formato padrão (`422` com
`{ errors, fields }`, `404` com `{ error }`). Datas `AAAA-MM-DD`; horários ISO 8601.

## Mentorias

| Método e rota | Corpo / parâmetros | Resposta |
| --- | --- | --- |
| `GET /mentorships` | | `{ data: Mentorship[] }` (ativas, pausadas, encerradas; depois início mais recente) |
| `POST /mentorships` | `{ mentorship: {...}, use_suggested_questions?: boolean = true }` | `201 Mentorship` |
| `GET /mentorships/:id` | | `Mentorship` |
| `PATCH /mentorships/:id` | `{ mentorship: {...} }` | `Mentorship` |
| `DELETE /mentorships/:id` | | `204` |
| `GET /mentorships/:id/overview` | | `Overview` |

```ts
Mentorship = {
  id, mentor_name, topic: string | null, description: string | null, started_on, ended_on: string | null,
  cadence: string | null, status: 'active' | 'paused' | 'finished', created_at, updated_at,
  summary: { goals_open: number, goals_achieved: number, action_items_open: number, last_meeting_on: string | null }
}

Overview = {
  questions: { total, answered },
  goals: { total, achieved, average_progress: number | null },      // sem abandonados
  action_items: { total, done, overdue, next: ActionItem[] },        // next: até 5 abertas por prazo
  meetings: { held, last_held_on: string | null, days_since_last: number | null,
              next_on: string | null, average_rating: number | null },
  competencies: { total, assessments, average_delta: number | null }
}
```

## Perguntas do questionário

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /mentorships/:id/questions` | | `{ data: Question[] }` por posição |
| `POST /mentorships/:id/questions` | `{ question: { prompt, answer? } }` | `201 Question` (no fim) |
| `PATCH /questions/:id` | `{ question: { prompt?, answer? } }` | `Question` |
| `POST /questions/:id/move` | `{ direction: 'up' \| 'down' }` | `{ data: Question[] }` |
| `DELETE /questions/:id` | | `204` |

`Question = { id, mentorship_id, position, prompt, answer: string | null, answered: boolean, updated_at }`

## Objetivos

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /mentorships/:id/goals` | | `{ data: Goal[] }` (abertos por prazo, depois alcançados e abandonados) |
| `POST /mentorships/:id/goals` | `{ goal: {...} }` | `201 Goal` |
| `PATCH /goals/:id` | `{ goal: {...} }` | `Goal` |
| `DELETE /goals/:id` | | `204` |

`Goal = { id, mentorship_id, title, success_criteria, description, target_on, status, progress, overdue: boolean, action_items: { total, done }, created_at, updated_at }`

## Encontros

| Método e rota | Corpo / parâmetros | Resposta |
| --- | --- | --- |
| `GET /mentorships/:id/meetings` | `?q=&page=` | `{ data: Meeting[], meta }` (mais recente primeiro) |
| `POST /mentorships/:id/meetings` | `{ meeting: {...} }` (vazio = hoje) | `201 Meeting` |
| `GET /meetings/:id` | | `Meeting` |
| `PATCH /meetings/:id` | `{ meeting: {...} }` | `Meeting` |
| `DELETE /meetings/:id` | | `204` |

`Meeting = { id, mentorship_id, mentor_name, held_on, agenda, notes, takeaways, rating: number | null, tags: string[], action_items: { total, done }, created_at, updated_at }`

## Ações

| Método e rota | Corpo / parâmetros | Resposta |
| --- | --- | --- |
| `GET /mentorships/:id/action_items` | `?meeting_id=&status=open\|done` | `{ data: ActionItem[] }` |
| `POST /mentorships/:id/action_items` | `{ action_item: { title, due_on?, meeting_id?, goal_id? } }` | `201 ActionItem` |
| `PATCH /action_items/:id` | `{ action_item: { ..., done?: boolean } }` | `ActionItem` |
| `DELETE /action_items/:id` | | `204` |

`ActionItem = { id, mentorship_id, meeting_id, goal_id, goal_title: string | null, meeting_held_on: string | null, title, due_on, completed_at, done: boolean, overdue: boolean, created_at, updated_at }`

## Competências e autoavaliação

| Método e rota | Corpo | Resposta |
| --- | --- | --- |
| `GET /mentorships/:id/competencies` | | `{ data: Competency[] }` |
| `POST /mentorships/:id/competencies` | `{ competency: { name } }` | `201 Competency` |
| `PATCH /competencies/:id` | `{ competency: { name } }` | `Competency` |
| `DELETE /competencies/:id` | | `204` |
| `GET /mentorships/:id/assessments` | | `Assessments` |
| `POST /mentorships/:id/assessments` | `{ rated_on, ratings: [{ competency_id, score: 1..5 \| null, comment? }] }` | `Assessments` |
| `DELETE /mentorships/:id/assessments/:rated_on` | | `204` |

No `POST`, nota `null` apaga a nota daquela competência na data; notas de competências de outra mentoria dão `422`.

```ts
Competency = { id, mentorship_id, name, position }
Assessments = {
  dates: string[],                                             // datas com notas, da mais antiga à mais recente
  competencies: (Competency & {
    ratings: { rated_on, score, comment: string | null }[],    // por data
    first: number | null, last: number | null, delta: number | null
  })[]
}
```
