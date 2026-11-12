import { useState } from 'react'
import type { FormEvent } from 'react'
import { MENTORSHIP_STATUS, errorMessage, today } from '../labels'
import type { Mentorship, MentorshipInput, MentorshipStatus } from '../types'
import { MarkdownField } from './MarkdownField'

interface Props {
  mentorship?: Mentorship
  submitLabel: string
  onSubmit: (input: MentorshipInput, useSuggestedQuestions: boolean) => Promise<void>
}

type FormState = Required<MentorshipInput>

function toForm(m?: Mentorship): FormState {
  return {
    mentor_name: m?.mentor_name ?? '',
    topic: m?.topic ?? '',
    description: m?.description ?? '',
    started_on: m?.started_on ?? today(),
    ended_on: m?.ended_on ?? '',
    cadence: m?.cadence ?? '',
    status: m?.status ?? 'active',
  }
}

export function MentorshipForm({ mentorship, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<FormState>(() => toForm(mentorship))
  const [suggested, setSuggested] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => setForm((c) => ({ ...c, [key]: value }))

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    try {
      await onSubmit(form, suggested)
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="form" onSubmit={submit}>
      <label>
        Mentor
        <input value={form.mentor_name} onChange={(e) => set('mentor_name', e.target.value)} required maxLength={100}
          autoFocus={!mentorship} placeholder="Nome de quem vai te mentorar" />
      </label>
      <label>
        Tema ou foco
        <input value={form.topic} onChange={(e) => set('topic', e.target.value)} maxLength={200}
          placeholder="Ex.: liderança técnica, transição para gestão" />
      </label>
      <div className="row">
        <label>
          Início
          <input type="date" value={form.started_on} onChange={(e) => set('started_on', e.target.value)} required />
        </label>
        <label>
          Término (opcional)
          <input type="date" value={form.ended_on} onChange={(e) => set('ended_on', e.target.value)} min={form.started_on} />
        </label>
      </div>
      <div className="row">
        <label>
          Frequência combinada
          <input value={form.cadence} onChange={(e) => set('cadence', e.target.value)} maxLength={100} placeholder="Ex.: quinzenal, 1 h" />
        </label>
        {mentorship && (
          <label>
            Situação
            <select value={form.status} onChange={(e) => set('status', e.target.value as MentorshipStatus)}>
              {Object.entries(MENTORSHIP_STATUS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
          </label>
        )}
      </div>
      <MarkdownField label="Anotações gerais (Markdown)" value={form.description} onChange={(v) => set('description', v)} rows={4}
        placeholder="Como chegou a esta mentoria, combinados, links…" />
      {!mentorship && (
        <label className="check">
          <input type="checkbox" checked={suggested} onChange={(e) => setSuggested(e.target.checked)} />
          Começar o questionário com as 12 perguntas sugeridas
        </label>
      )}
      {error && <p className="error">{error}</p>}
      <button type="submit" className="btn primary" disabled={saving || !form.mentor_name.trim()}>
        {saving ? 'Salvando…' : submitLabel}
      </button>
    </form>
  )
}
