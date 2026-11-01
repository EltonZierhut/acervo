import { useState } from 'react'
import type { FormEvent } from 'react'
import { initiativesApi } from '../api'
import type { Run } from '../types'

// Perguntas da IA ainda sem resposta. Ao responder todas, a tarefa volta para a fila.
export function RunQuestions({ run, onAnswered }: { run: Run; onAnswered: () => void }) {
  const pending = run.questions.filter((question) => question.answered_at === null)
  const [answers, setAnswers] = useState<Record<number, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await initiativesApi.answerRun(run.id, pending.map((q) => ({ question_id: q.id, answer: answers[q.id] ?? '' })))
      onAnswered()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível enviar')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="form run-questions" onSubmit={(e) => void submit(e)}>
      {pending.map((question) => (
        <label key={question.id}>
          <span className="pre">{question.body}</span>
          <textarea
            rows={2}
            required
            maxLength={10000}
            value={answers[question.id] ?? ''}
            onChange={(e) => setAnswers((current) => ({ ...current, [question.id]: e.target.value }))}
          />
        </label>
      ))}
      {error && <p className="error small">{error}</p>}
      <button type="submit" className="btn primary" disabled={busy}>Responder e voltar para a fila</button>
    </form>
  )
}
