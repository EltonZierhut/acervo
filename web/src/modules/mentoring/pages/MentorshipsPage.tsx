import { Link } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { MENTORSHIP_STATUS, formatDate } from '../labels'

export function MentorshipsPage() {
  const list = useAsync(() => mentoringApi.listMentorships(), [])
  const mentorships = list.data?.data ?? []

  return (
    <section>
      <header className="page-header">
        <h1>Mentoria</h1>
        <Link to="/mentoria/nova" className="btn primary">+ Nova mentoria</Link>
      </header>

      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}
      {list.data && mentorships.length === 0 && (
        <div className="empty">
          <p>Nenhuma mentoria ainda.</p>
          <p className="small">Cadastre a mentoria e comece pelo questionário inicial: ele norteia os objetivos, os encontros e a sua evolução.</p>
          <Link to="/mentoria/nova" className="btn primary">Começar</Link>
        </div>
      )}

      <ul className="card-list grid">
        {mentorships.map((m) => (
          <li key={m.id}>
            <Link to={`/mentoria/${m.id}`} className="card initiative-card mt-mentorship-card">
              <span className="card-title">{m.mentor_name}</span>
              {m.topic && <span className="muted mt-break">{m.topic}</span>}
              <span className="meta">
                <span className={`status mt-mstatus-${m.status}`}>{MENTORSHIP_STATUS[m.status]}</span>
                <span className="muted small">Desde {formatDate(m.started_on)}</span>
              </span>
              <span className="small muted">
                {m.summary.goals_open} objetivo{m.summary.goals_open === 1 ? '' : 's'} em aberto · {m.summary.goals_achieved} alcançado{m.summary.goals_achieved === 1 ? '' : 's'}
                {' · '}{m.summary.action_items_open} aç{m.summary.action_items_open === 1 ? 'ão aberta' : 'ões abertas'}
              </span>
              <span className="small muted">
                {m.summary.last_meeting_on ? `Último encontro: ${formatDate(m.summary.last_meeting_on)}` : 'Nenhum encontro ainda'}
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}
