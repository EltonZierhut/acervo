import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { Markdown } from '../components/Markdown'
import { errorMessage, formatDate, isFuture } from '../labels'
import type { Mentorship } from '../types'

export function MeetingsTab({ mentorship }: { mentorship: Mentorship }) {
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)
  const q = useDebounce(query.trim(), 300)
  const [creating, setCreating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const list = useAsync(() => mentoringApi.listMeetings(mentorship.id, { q, page }), [mentorship.id, q, page])

  // Cria o encontro de hoje e abre para escrever (SC-002).
  const create = async () => {
    setCreating(true)
    setError(null)
    try {
      const meeting = await mentoringApi.createMeeting(mentorship.id)
      navigate(`/mentoria/encontros/${meeting.id}`)
    } catch (err) {
      setError(errorMessage(err))
      setCreating(false)
    }
  }

  const meetings = list.data?.data ?? []
  const totalPages = list.data?.meta.total_pages ?? 1

  return (
    <div className="mt-meetings">
      <div className="filters">
        <input className="search" type="search" aria-label="Buscar nos encontros" placeholder="Buscar na pauta, anotações, aprendizados…"
          value={query} onChange={(e) => { setQuery(e.target.value); setPage(1) }} />
        <button type="button" className="btn primary" onClick={create} disabled={creating}>+ Novo encontro</button>
      </div>
      {error && <p className="error">{error}</p>}
      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}
      {list.data && meetings.length === 0 && (
        <div className="empty">{q ? 'Nada encontrado.' : 'Nenhum encontro registrado. Antes do próximo, crie o encontro e escreva a pauta.'}</div>
      )}

      <ul className="card-list">
        {meetings.map((meeting) => (
          <li key={meeting.id} className="card">
            <Link to={`/mentoria/encontros/${meeting.id}`} className="card-title brag-title">Encontro de {formatDate(meeting.held_on)}</Link>
            <div className="meta">
              {isFuture(meeting.held_on) && <span className="chip">Agendado</span>}
              {meeting.rating && <span className="muted" aria-label={`Nota ${meeting.rating} de 5`}>Nota {meeting.rating}/5</span>}
              {meeting.action_items.total > 0 && <span className="muted">{meeting.action_items.done}/{meeting.action_items.total} ações</span>}
              {meeting.tags.map((tag) => <span key={tag} className="badge">{tag}</span>)}
            </div>
            {(meeting.takeaways || meeting.agenda) && (
              <div className="clamp"><Markdown>{meeting.takeaways || meeting.agenda || ''}</Markdown></div>
            )}
          </li>
        ))}
      </ul>

      {totalPages > 1 && (
        <div className="pager">
          <button type="button" disabled={page <= 1} onClick={() => setPage(page - 1)}>Anterior</button>
          <span className="muted small">Página {page} de {totalPages}</span>
          <button type="button" disabled={page >= totalPages} onClick={() => setPage(page + 1)}>Próxima</button>
        </div>
      )}
    </div>
  )
}
