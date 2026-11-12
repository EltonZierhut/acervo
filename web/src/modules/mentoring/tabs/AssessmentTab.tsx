import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { ScorePicker } from '../components/ScorePicker'
import { COMPETENCY_SUGGESTIONS, errorMessage, formatDate, signed, today } from '../labels'
import type { Assessments, CompetencyEvolution, Mentorship } from '../types'

// Autoavaliação por competências (spec 010, História 4): notas de 1 a 5 por data e a evolução de cada uma.
export function AssessmentTab({ mentorship }: { mentorship: Mentorship }) {
  const data = useAsync(() => mentoringApi.assessments(mentorship.id), [mentorship.id])
  const [assessing, setAssessing] = useState(false)

  if (data.error) return <p className="error">{data.error}</p>
  if (!data.data) return <p className="muted">Carregando…</p>

  const { competencies, dates } = data.data

  return (
    <div className="mt-assessment">
      <p className="muted small">
        Escolha as competências que quer desenvolver e dê uma nota de 1 (iniciante) a 5 (referência) de tempos em tempos,
        por exemplo a cada mês ou a cada três encontros. A evolução é a diferença entre a primeira e a última nota.
      </p>

      {competencies.length > 0 && !assessing && (
        <button type="button" className="btn primary" onClick={() => setAssessing(true)}>
          {dates.length === 0 ? 'Fazer a autoavaliação inicial' : 'Nova autoavaliação'}
        </button>
      )}
      {assessing && (
        <AssessmentForm mentorshipId={mentorship.id} assessments={data.data}
          onSaved={() => { setAssessing(false); data.reload() }} onCancel={() => setAssessing(false)} />
      )}

      {dates.length > 0 && <Evolution competencies={competencies} dates={dates} mentorshipId={mentorship.id} onChanged={data.reload} />}

      <CompetencyManager mentorshipId={mentorship.id} competencies={competencies} onChanged={data.reload} />
    </div>
  )
}

function AssessmentForm({ mentorshipId, assessments, onSaved, onCancel }: {
  mentorshipId: number; assessments: Assessments; onSaved: () => void; onCancel: () => void
}) {
  // Ao escolher uma data que já tem notas, elas aparecem para corrigir (salvar substitui).
  const notesOn = (date: string) =>
    Object.fromEntries(assessments.competencies.map((c) => {
      const rating = c.ratings.find((r) => r.rated_on === date)
      return [c.id, { score: rating?.score ?? null, comment: rating?.comment ?? '' }]
    }))
  const [ratedOn, setRatedOn] = useState(today())
  const [scores, setScores] = useState(() => notesOn(today()))
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const filled = Object.values(scores).filter((s) => s.score !== null).length
  const existing = assessments.dates.includes(ratedOn)

  const changeDate = (date: string) => {
    setRatedOn(date)
    if (date) setScores(notesOn(date))
  }

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    try {
      await mentoringApi.saveAssessment(mentorshipId, ratedOn, assessments.competencies.map((c) => ({
        competency_id: c.id, score: scores[c.id].score, comment: scores[c.id].comment,
      })))
      onSaved()
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="card form mt-assessment-form" onSubmit={save}>
      <label>
        Data da autoavaliação
        <input type="date" value={ratedOn} onChange={(e) => changeDate(e.target.value)} max={today()} required />
      </label>
      {existing && <p className="notice">Já há notas nesta data; salvar substitui.</p>}
      {assessments.competencies.map((c) => (
        <fieldset key={c.id} className="mt-rate">
          <legend>{c.name}</legend>
          <ScorePicker label={`Nota para ${c.name}`} value={scores[c.id].score}
            onChange={(score) => setScores((s) => ({ ...s, [c.id]: { ...s[c.id], score } }))} />
          <input value={scores[c.id].comment} placeholder="Comentário (opcional): por que esta nota?" maxLength={1000}
            aria-label={`Comentário sobre ${c.name}`}
            onChange={(e) => setScores((s) => ({ ...s, [c.id]: { ...s[c.id], comment: e.target.value } }))} />
        </fieldset>
      ))}
      {error && <p className="error">{error}</p>}
      <div className="actions mt-wrap">
        <button type="submit" className="btn primary" disabled={saving || !ratedOn || (filled === 0 && !existing)}>
          {saving ? 'Salvando…' : `Salvar (${filled} de ${assessments.competencies.length})`}
        </button>
        <button type="button" className="btn" onClick={onCancel}>Cancelar</button>
      </div>
    </form>
  )
}

function Evolution({ competencies, dates, mentorshipId, onChanged }: {
  competencies: CompetencyEvolution[]; dates: string[]; mentorshipId: number; onChanged: () => void
}) {
  const removeDate = async (date: string) => {
    if (!window.confirm(`Apagar todas as notas de ${formatDate(date)}?`)) return
    await mentoringApi.deleteAssessment(mentorshipId, date)
    onChanged()
  }

  return (
    <section>
      <h2 className="mt-h2">Evolução</h2>
      <ul className="card-list">
        {competencies.map((c) => (
          <li key={c.id} className="card mt-evolution">
            <div className="mt-goal-head">
              <strong className="mt-break">{c.name}</strong>
              {c.delta !== null && (
                <span className={`mt-delta ${c.delta > 0 ? 'up' : c.delta < 0 ? 'down' : ''}`}>{signed(c.delta)}</span>
              )}
            </div>
            {c.ratings.length === 0 ? (
              <span className="muted small">Sem notas ainda.</span>
            ) : (
              <>
                <div className="mt-bars" aria-label={`Notas de ${c.name} ao longo do tempo`}>
                  {c.ratings.map((r) => (
                    <span key={r.rated_on} className="mt-bar" title={`${formatDate(r.rated_on)}: ${r.score}${r.comment ? ` — ${r.comment}` : ''}`}>
                      <span className="mt-bar-fill" style={{ height: `${r.score * 20}%` }} />
                      <span className="mt-bar-value">{r.score}</span>
                    </span>
                  ))}
                </div>
                <span className="small muted">
                  {c.ratings.length === 1 ? `Nota ${c.first} em ${formatDate(c.ratings[0].rated_on)}` : `De ${c.first} para ${c.last}`}
                  {c.ratings[c.ratings.length - 1].comment ? ` · ${c.ratings[c.ratings.length - 1].comment}` : ''}
                </span>
              </>
            )}
          </li>
        ))}
      </ul>
      <details className="mt-dates">
        <summary>Autoavaliações feitas ({dates.length})</summary>
        <ul className="task-links">
          {dates.slice().reverse().map((date) => (
            <li key={date}>
              <span>{formatDate(date)}</span>
              <button type="button" className="link-button" onClick={() => removeDate(date)}>Apagar</button>
            </li>
          ))}
        </ul>
      </details>
    </section>
  )
}

function CompetencyManager({ mentorshipId, competencies, onChanged }: {
  mentorshipId: number; competencies: CompetencyEvolution[]; onChanged: () => void
}) {
  const [name, setName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const used = new Set(competencies.map((c) => c.name.toLowerCase()))

  const add = async (value: string) => {
    if (!value.trim()) return
    setError(null)
    try {
      await mentoringApi.createCompetency(mentorshipId, value)
      setName('')
      onChanged()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const rename = async (id: number, current: string) => {
    const next = window.prompt('Novo nome da competência', current)
    if (!next || next.trim() === current) return
    try {
      await mentoringApi.updateCompetency(id, next)
      onChanged()
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const remove = async (id: number, current: string) => {
    if (!window.confirm(`Apagar "${current}" e todas as notas dela?`)) return
    await mentoringApi.deleteCompetency(id)
    onChanged()
  }

  const suggestions = COMPETENCY_SUGGESTIONS.filter((s) => !used.has(s.toLowerCase()))

  return (
    <section>
      <h2 className="mt-h2">Competências</h2>
      {competencies.length === 0 && <p className="muted">Nenhuma competência ainda. Comece com 3 a 5.</p>}
      <ul className="task-links mt-competencies">
        {competencies.map((c) => (
          <li key={c.id}>
            <span className="mt-break">{c.name}</span>
            <span className="actions">
              <button type="button" className="link-button" onClick={() => rename(c.id, c.name)}>Renomear</button>
              <button type="button" className="link-button" onClick={() => remove(c.id, c.name)}>Apagar</button>
            </span>
          </li>
        ))}
      </ul>
      <form className="quick-add-row" onSubmit={(e) => { e.preventDefault(); add(name) }}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Nova competência" aria-label="Nome da competência"
          maxLength={100} />
        <button type="submit" className="btn primary" disabled={!name.trim()}>Adicionar</button>
      </form>
      {suggestions.length > 0 && (
        <div className="mt-suggestions" aria-label="Sugestões">
          {suggestions.map((s) => <button key={s} type="button" className="btn small-btn chip" onClick={() => add(s)}>+ {s}</button>)}
        </div>
      )}
      {error && <p className="error">{error}</p>}
    </section>
  )
}
