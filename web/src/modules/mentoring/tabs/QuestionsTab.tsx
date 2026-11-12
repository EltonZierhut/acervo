import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { Markdown } from '../components/Markdown'
import { MarkdownField } from '../components/MarkdownField'
import { ProgressBar } from '../components/ProgressBar'
import { errorMessage } from '../labels'
import type { Mentorship, Question } from '../types'

// Texto simples para mandar ao mentor: pergunta numerada e a resposta logo abaixo.
function questionnaireText(mentorship: Mentorship, questions: Question[]) {
  const header = `Questionário inicial — mentoria com ${mentorship.mentor_name}`
  const body = questions.map((q, i) => `${i + 1}. ${q.prompt}\n${q.answer?.trim() || '(sem resposta)'}`)
  return [header, ...body].join('\n\n')
}

export function QuestionsTab({ mentorship }: { mentorship: Mentorship }) {
  const list = useAsync(() => mentoringApi.listQuestions(mentorship.id), [mentorship.id])
  const [questions, setQuestions] = useState<Question[] | null>(null)
  const [editing, setEditing] = useState<number | null>(null)
  const [newPrompt, setNewPrompt] = useState('')
  const [notice, setNotice] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  // A lista local acompanha as mudanças sem recarregar tudo.
  const items = questions ?? list.data?.data ?? []
  const answered = items.filter((q) => q.answered).length
  const replace = (question: Question) => setQuestions(items.map((q) => (q.id === question.id ? question : q)))

  const add = async (event: FormEvent) => {
    event.preventDefault()
    if (!newPrompt.trim()) return
    setError(null)
    try {
      const question = await mentoringApi.createQuestion(mentorship.id, newPrompt)
      setQuestions([...items, question])
      setNewPrompt('')
    } catch (err) {
      setError(errorMessage(err))
    }
  }

  const move = async (question: Question, direction: 'up' | 'down') => {
    const result = await mentoringApi.moveQuestion(question.id, direction)
    setQuestions(result.data)
  }

  const remove = async (question: Question) => {
    if (!window.confirm('Apagar esta pergunta e a resposta?')) return
    await mentoringApi.deleteQuestion(question.id)
    setQuestions(items.filter((q) => q.id !== question.id))
  }

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(questionnaireText(mentorship, items))
      setNotice('Questionário copiado. Cole onde quiser enviar ao mentor.')
    } catch {
      setNotice('Não foi possível copiar neste navegador.')
    }
  }

  if (list.error) return <p className="error">{list.error}</p>
  if (!list.data) return <p className="muted">Carregando…</p>

  return (
    <div className="mt-questions">
      <div className="mt-questions-head">
        <div>
          <strong>{answered} de {items.length} respondidas</strong>
          {items.length > 0 && <ProgressBar percent={(answered / items.length) * 100} label="Perguntas respondidas" />}
        </div>
        <button type="button" className="btn" onClick={copy} disabled={items.length === 0}>Copiar questionário</button>
      </div>
      <p className="muted small">
        Responda com calma: as respostas viram a base dos objetivos. Ajuste o texto das perguntas ou acrescente as que o mentor enviar.
      </p>
      {notice && <p className="notice" role="status">{notice}</p>}

      <ol className="mt-question-list">
        {items.map((question, index) => (
          <li key={question.id} className={`card mt-question${question.answered ? ' answered' : ''}`}>
            {editing === question.id ? (
              <QuestionEditor question={question} number={index + 1}
                onSaved={(q) => { replace(q); setEditing(null) }} onCancel={() => setEditing(null)} />
            ) : (
              <>
                <div className="mt-question-top">
                  <span className="mt-question-number" aria-hidden>{index + 1}</span>
                  <p className="mt-question-prompt">{question.prompt}</p>
                </div>
                {question.answered ? (
                  <div className="mt-answer"><Markdown>{question.answer ?? ''}</Markdown></div>
                ) : (
                  <p className="muted small">Ainda sem resposta.</p>
                )}
                <div className="actions mt-wrap">
                  <button type="button" className={`btn${question.answered ? '' : ' primary'}`} onClick={() => setEditing(question.id)}>
                    {question.answered ? 'Editar' : 'Responder'}
                  </button>
                  <button type="button" className="btn" onClick={() => move(question, 'up')} disabled={index === 0}
                    aria-label={`Subir a pergunta ${index + 1}`}>↑</button>
                  <button type="button" className="btn" onClick={() => move(question, 'down')} disabled={index === items.length - 1}
                    aria-label={`Descer a pergunta ${index + 1}`}>↓</button>
                  <button type="button" className="btn danger" onClick={() => remove(question)}>Apagar</button>
                </div>
              </>
            )}
          </li>
        ))}
      </ol>

      <form className="quick-add card" onSubmit={add}>
        <div className="quick-add-row">
          <input value={newPrompt} onChange={(e) => setNewPrompt(e.target.value)} placeholder="Nova pergunta (ex.: enviada pelo mentor)"
            aria-label="Texto da nova pergunta" maxLength={500} />
          <button type="submit" className="btn primary" disabled={!newPrompt.trim()}>Adicionar</button>
        </div>
        {error && <p className="error">{error}</p>}
      </form>
    </div>
  )
}

function QuestionEditor({ question, number, onSaved, onCancel }: {
  question: Question; number: number; onSaved: (q: Question) => void; onCancel: () => void
}) {
  const [prompt, setPrompt] = useState(question.prompt)
  const [answer, setAnswer] = useState(question.answer ?? '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const save = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    try {
      onSaved(await mentoringApi.updateQuestion(question.id, { prompt, answer }))
    } catch (err) {
      setError(errorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="form mt-edit" onSubmit={save}>
      <label>
        Pergunta {number}
        <textarea rows={2} value={prompt} onChange={(e) => setPrompt(e.target.value)} required maxLength={500} />
      </label>
      <MarkdownField label="Resposta (Markdown)" value={answer} onChange={setAnswer} rows={7} autoFocus
        placeholder="Escreva com suas palavras. Aceita listas, **negrito** e links." />
      {error && <p className="error">{error}</p>}
      <div className="actions mt-wrap">
        <button type="submit" className="btn primary" disabled={saving || !prompt.trim()}>{saving ? 'Salvando…' : 'Salvar'}</button>
        <button type="button" className="btn" onClick={onCancel}>Cancelar</button>
      </div>
    </form>
  )
}
