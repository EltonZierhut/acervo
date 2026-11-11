import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { mentoringApi } from '../api'
import { MentorshipForm } from '../components/MentorshipForm'
import { MENTORSHIP_STATUS, formatDate } from '../labels'
import { ActionItemsTab } from '../tabs/ActionItemsTab'
import { AssessmentTab } from '../tabs/AssessmentTab'
import { GoalsTab } from '../tabs/GoalsTab'
import { MeetingsTab } from '../tabs/MeetingsTab'
import { OverviewTab } from '../tabs/OverviewTab'
import { QuestionsTab } from '../tabs/QuestionsTab'
import { TABS, tabSlug } from '../tabs/tabs'
import type { TabKey } from '../tabs/tabs'
import type { Mentorship } from '../types'

export function MentorshipPage() {
  const id = Number(useParams().id)
  const validId = Number.isInteger(id) && id > 0
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const [mentorship, setMentorship] = useState<Mentorship | null>(null)
  const [loadError, setLoadError] = useState<{ status: number; message: string } | null>(null)
  const [saved, setSaved] = useState(false)

  const load = useCallback(() => {
    if (!validId) return
    mentoringApi.getMentorship(id).then(setMentorship)
      .catch((err: Error) => setLoadError({ status: err instanceof ApiError ? err.status : 0, message: err.message }))
  }, [id, validId])

  useEffect(() => load(), [load])

  const current: TabKey = TABS.find((tab) => tab.slug === params.get('aba'))?.key ?? 'overview'
  const goTo = (key: TabKey) => {
    setSaved(false)
    setParams((c) => { const n = new URLSearchParams(c); n.set('aba', tabSlug(key)); return n })
  }

  if (!validId || loadError?.status === 404) {
    return (
      <div className="empty">
        <p>Mentoria não encontrada.</p>
        <Link to="/mentoria">Voltar para a lista</Link>
      </div>
    )
  }
  if (loadError) return <p className="error">{loadError.message}</p>
  if (!mentorship) return <p className="muted">Carregando…</p>

  const remove = async () => {
    if (!window.confirm(`Apagar a mentoria com ${mentorship.mentor_name}, com questionário, objetivos, encontros e notas? Não dá para desfazer.`)) return
    await mentoringApi.deleteMentorship(mentorship.id)
    navigate('/mentoria', { replace: true })
  }

  return (
    <section>
      <Link to="/mentoria" className="back">← Mentoria</Link>
      <header className="initiative-header">
        <h1 className="mt-break">Mentoria com {mentorship.mentor_name}</h1>
        <div className="meta">
          <span className={`status mt-mstatus-${mentorship.status}`}>{MENTORSHIP_STATUS[mentorship.status]}</span>
          {mentorship.topic && <span className="mt-break">{mentorship.topic}</span>}
          <span className="muted small">
            Desde {formatDate(mentorship.started_on)}{mentorship.ended_on ? ` até ${formatDate(mentorship.ended_on)}` : ''}
            {mentorship.cadence ? ` · ${mentorship.cadence}` : ''}
          </span>
        </div>
      </header>

      <nav className="tabs mt-tabs" aria-label="Seções da mentoria">
        {TABS.map((tab) => (
          <button key={tab.key} type="button" className={`tab${current === tab.key ? ' active' : ''}`}
            aria-current={current === tab.key ? 'page' : undefined} onClick={() => goTo(tab.key)}>
            {tab.label}
          </button>
        ))}
      </nav>

      {current === 'overview' && <OverviewTab mentorship={mentorship} goTo={goTo} />}
      {current === 'questions' && <QuestionsTab mentorship={mentorship} />}
      {current === 'goals' && <GoalsTab mentorship={mentorship} />}
      {current === 'meetings' && <MeetingsTab mentorship={mentorship} />}
      {current === 'actions' && <ActionItemsTab mentorship={mentorship} />}
      {current === 'assessment' && <AssessmentTab mentorship={mentorship} />}
      {current === 'details' && (
        <>
          {saved && <p className="notice" role="status">Alterações salvas.</p>}
          <MentorshipForm key={mentorship.updated_at} mentorship={mentorship} submitLabel="Salvar" onSubmit={async (input) => {
            setMentorship(await mentoringApi.updateMentorship(mentorship.id, input))
            setSaved(true)
          }} />
          <div className="danger-zone">
            <button type="button" className="btn danger" onClick={remove}>Apagar mentoria</button>
          </div>
        </>
      )}
    </section>
  )
}
