import type { ReactNode } from 'react'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { ActionItemList } from '../components/ActionItemList'
import { ProgressBar } from '../components/ProgressBar'
import { formatDate, signed } from '../labels'
import type { Mentorship } from '../types'
import type { TabKey } from './tabs'

function Stat({ title, value, detail, onOpen }: { title: string; value: ReactNode; detail?: ReactNode; onOpen: () => void }) {
  return (
    <button type="button" className="card mt-stat" onClick={onOpen}>
      <span className="mt-stat-title">{title}</span>
      <span className="mt-stat-value">{value}</span>
      {detail && <span className="small muted">{detail}</span>}
    </button>
  )
}

// Painel da mentoria (spec 010, História 5). Cada indicador abre a aba correspondente.
export function OverviewTab({ mentorship, goTo }: { mentorship: Mentorship; goTo: (tab: TabKey) => void }) {
  const overview = useAsync(() => mentoringApi.overview(mentorship.id), [mentorship.id])
  const goals = useAsync(() => mentoringApi.listGoals(mentorship.id), [mentorship.id])

  if (overview.error) return <p className="error">{overview.error}</p>
  if (!overview.data) return <p className="muted">Carregando…</p>

  const { questions, goals: goalStats, action_items: actions, meetings, competencies } = overview.data
  const dash = '—'
  const nextStep =
    questions.total > 0 && questions.answered < questions.total
      ? { text: 'Continue respondendo o questionário inicial: ele norteia os objetivos.', tab: 'questions' as const, label: 'Responder' }
      : goalStats.total === 0
        ? { text: 'Defina os objetivos da mentoria a partir das suas respostas.', tab: 'goals' as const, label: 'Criar objetivo' }
        : meetings.held === 0
          ? { text: 'Registre o primeiro encontro: pauta, anotações e ações combinadas.', tab: 'meetings' as const, label: 'Ver encontros' }
          : competencies.assessments === 0
            ? { text: 'Faça uma autoavaliação inicial para medir sua evolução.', tab: 'assessment' as const, label: 'Autoavaliar' }
            : null

  return (
    <div className="mt-overview">
      {nextStep && (
        <div className="notice mt-next">
          <span>{nextStep.text}</span>
          <button type="button" className="btn small-btn" onClick={() => goTo(nextStep.tab)}>{nextStep.label}</button>
        </div>
      )}

      <div className="mt-stats">
        <Stat title="Questionário" onOpen={() => goTo('questions')}
          value={questions.total ? `${questions.answered} de ${questions.total}` : dash}
          detail={questions.total ? <ProgressBar percent={(questions.answered / questions.total) * 100} label="Perguntas respondidas" /> : 'Sem perguntas'} />
        <Stat title="Objetivos" onOpen={() => goTo('goals')}
          value={goalStats.average_progress === null ? dash : `${goalStats.average_progress}%`}
          detail={goalStats.total ? `${goalStats.achieved} de ${goalStats.total} alcançados` : 'Nenhum objetivo'} />
        <Stat title="Ações" onOpen={() => goTo('actions')}
          value={actions.total ? `${actions.done} de ${actions.total}` : dash}
          detail={actions.overdue ? <span className="overdue">{actions.overdue} atrasada{actions.overdue > 1 ? 's' : ''}</span> : actions.total ? 'Nenhuma atrasada' : 'Nenhuma ação'} />
        <Stat title="Encontros" onOpen={() => goTo('meetings')}
          value={meetings.held || dash}
          detail={meetings.last_held_on
            ? `Último em ${formatDate(meetings.last_held_on)} (${meetings.days_since_last === 0 ? 'hoje' : `há ${meetings.days_since_last} dia${meetings.days_since_last === 1 ? '' : 's'}`})`
            : 'Nenhum realizado'} />
        <Stat title="Nota dos encontros" onOpen={() => goTo('meetings')}
          value={meetings.average_rating === null ? dash : meetings.average_rating.toLocaleString('pt-BR')}
          detail={meetings.next_on ? `Próximo: ${formatDate(meetings.next_on)}` : 'de 1 a 5'} />
        <Stat title="Evolução das competências" onOpen={() => goTo('assessment')}
          value={competencies.average_delta === null ? dash : signed(competencies.average_delta)}
          detail={competencies.total ? `${competencies.total} competência${competencies.total > 1 ? 's' : ''}, ${competencies.assessments} autoavaliaç${competencies.assessments === 1 ? 'ão' : 'ões'}` : 'Nenhuma competência'} />
      </div>

      <header className="page-header section">
        <h2>Próximas ações</h2>
        <button type="button" className="btn small-btn" onClick={() => goTo('actions')}>Todas</button>
      </header>
      {actions.next.length === 0 ? (
        <p className="muted">Nenhuma ação aberta.</p>
      ) : (
        <ActionItemList mentorshipId={mentorship.id} items={actions.next} goals={goals.data?.data ?? []}
          onChanged={overview.reload} allowCreate={false} />
      )}
    </div>
  )
}
