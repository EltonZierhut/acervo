import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { ActionItemList } from '../components/ActionItemList'
import { MarkdownField } from '../components/MarkdownField'
import { ScorePicker } from '../components/ScorePicker'
import { errorMessage, formatDate, isFuture } from '../labels'
import type { Meeting } from '../types'

export function MeetingPage() {
  const id = Number(useParams().id)
  const meeting = useAsync(() => mentoringApi.getMeeting(id), [id])

  if (meeting.error) {
    return (
      <div className="empty">
        <p>{meeting.error}</p>
        <Link to="/mentoria">Voltar para Mentoria</Link>
      </div>
    )
  }
  if (!meeting.data) return <p className="muted">Carregando…</p>
  return <MeetingEditor key={meeting.data.id} meeting={meeting.data} />
}

function MeetingEditor({ meeting }: { meeting: Meeting }) {
  const navigate = useNavigate()
  const back = `/mentoria/${meeting.mentorship_id}?aba=encontros`
  const [form, setForm] = useState({
    held_on: meeting.held_on, agenda: meeting.agenda ?? '', notes: meeting.notes ?? '', takeaways: meeting.takeaways ?? '',
    rating: meeting.rating, tags: meeting.tags.join(', '),
  })
  const [status, setStatus] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const actions = useAsync(() => mentoringApi.listActionItems(meeting.mentorship_id, { meeting_id: meeting.id }), [meeting.id])
  const goals = useAsync(() => mentoringApi.listGoals(meeting.mentorship_id), [meeting.mentorship_id])

  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => {
    setStatus(null)
    setForm((c) => ({ ...c, [key]: value }))
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    try {
      await mentoringApi.updateMeeting(meeting.id, form)
      setStatus('Encontro salvo.')
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const remove = async () => {
    if (!window.confirm('Apagar este encontro? As ações combinadas nele continuam na lista de ações.')) return
    await mentoringApi.deleteMeeting(meeting.id)
    navigate(back, { replace: true })
  }

  return (
    <section>
      <Link to={back} className="back">← Mentoria com {meeting.mentor_name}</Link>
      <header className="page-header">
        <h1>Encontro de {formatDate(form.held_on)}</h1>
        {isFuture(form.held_on) && <span className="chip">Agendado</span>}
      </header>

      <form className="form" onSubmit={save}>
        <div className="row">
          <label>
            Data
            <input type="date" value={form.held_on} onChange={(e) => set('held_on', e.target.value)} required />
          </label>
          <label>
            Tags
            <input value={form.tags} onChange={(e) => set('tags', e.target.value)} placeholder="separadas por vírgula" />
          </label>
        </div>
        <MarkdownField label="Pauta (antes do encontro)" value={form.agenda} onChange={(v) => set('agenda', v)} rows={4}
          placeholder="O que quero levar: dúvidas, situações, progresso desde o último encontro…" autoFocus={!meeting.agenda && !meeting.notes} />
        <MarkdownField label="Anotações" value={form.notes} onChange={(v) => set('notes', v)} rows={6}
          placeholder="O que foi conversado, conselhos, referências…" />
        <MarkdownField label="Principais aprendizados" value={form.takeaways} onChange={(v) => set('takeaways', v)} rows={3}
          placeholder="Em poucas linhas: o que levo deste encontro" />
        <div className="label-block">
          <span className="field-label">Quanto este encontro me ajudou (1 a 5)</span>
          <ScorePicker label="Nota do encontro" value={form.rating} onChange={(v) => set('rating', v)} />
        </div>
        {error && <p className="error">{error}</p>}
        {status && <p className="notice" role="status">{status}</p>}
        <button type="submit" className="btn primary" disabled={saving}>{saving ? 'Salvando…' : 'Salvar encontro'}</button>
      </form>

      <h2 className="mt-h2">Ações combinadas</h2>
      {actions.error && <p className="error">{actions.error}</p>}
      {actions.data && (
        <ActionItemList mentorshipId={meeting.mentorship_id} meetingId={meeting.id} items={actions.data.data}
          goals={goals.data?.data ?? []} onChanged={actions.reload} showMeeting={false} />
      )}

      <div className="danger-zone">
        <button type="button" className="btn danger" onClick={remove}>Apagar encontro</button>
      </div>
    </section>
  )
}
