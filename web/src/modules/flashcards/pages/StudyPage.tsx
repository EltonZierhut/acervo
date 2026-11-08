import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { RATING_LABELS, flashcardsApi, formatTime } from '../api'
import { DueCounts } from '../components/DueCounts'
import { Markdown } from '../components/Markdown'
import type { Rating, Study } from '../types'

const RATINGS: Rating[] = [1, 2, 3, 4]

// Um cartão por vez: frente, "Mostrar resposta", verso e quatro botões. No computador, espaço revela e 1 a 4
// respondem; no celular, tudo por toque.
export function StudyPage() {
  const deckId = Number(useParams().deckId)
  const [study, setStudy] = useState<Study | null>(null)
  const [revealed, setRevealed] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const shownAt = useRef(0)

  const show = useCallback((next: Study) => {
    setStudy(next)
    setRevealed(false)
    shownAt.current = Date.now()
  }, [])

  const load = useCallback(() => {
    flashcardsApi.study(deckId)
      .then((next) => {
        setError(null)
        show(next)
      })
      .catch((err: Error) => setError(err.message))
  }, [deckId, show])

  useEffect(() => load(), [load])

  // Sem nada para agora: volta sozinho quando o próximo cartão em aprendizado vencer.
  const nextDueAt = study?.card ? null : study?.next_due_at
  useEffect(() => {
    if (!nextDueAt) return
    const delay = Math.min(Math.max(new Date(nextDueAt).getTime() - Date.now(), 1000), 60 * 60 * 1000)
    const timer = setTimeout(load, delay)
    return () => clearTimeout(timer)
  }, [nextDueAt, load])

  const answer = useCallback(async (rating: Rating) => {
    if (!study?.card || busy) return
    setBusy(true)
    setError(null)
    try {
      show(await flashcardsApi.review(study.card.id, rating, Date.now() - shownAt.current))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar a resposta')
    } finally {
      setBusy(false)
    }
  }, [study, busy, show])

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.ctrlKey || event.metaKey || event.altKey) return
      const target = event.target as HTMLElement | null
      if (target && ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)) return
      if (!study?.card) return
      if (!revealed && (event.key === ' ' || event.key === 'Enter')) {
        event.preventDefault()
        setRevealed(true)
      } else if (revealed && ['1', '2', '3', '4'].includes(event.key)) {
        event.preventDefault()
        void answer(Number(event.key) as Rating)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [study, revealed, answer])

  const card = study?.card

  return (
    <section className="fc-study">
      <div className="fc-study-top">
        <Link to={`/flashcards/${deckId}`} className="back">← {study?.deck.name ?? 'Baralho'}</Link>
        {study && <DueCounts counts={study.counts} />}
      </div>

      {error && <p className="error">{error}</p>}
      {!study && !error && <p className="muted">Carregando…</p>}

      {study && !card && (
        <div className="empty fc-done">
          {study.next_due_at ? (
            <>
              <p><strong>Pausa curta.</strong></p>
              <p>O próximo cartão em aprendizado volta às {formatTime(study.next_due_at)}. Esta tela atualiza sozinha.</p>
            </>
          ) : (
            <>
              <p><strong>Parabéns, terminou por hoje!</strong></p>
              <p>{study.due_tomorrow === 0 ? 'Nenhum cartão vence amanhã.' : `${study.due_tomorrow} ${study.due_tomorrow === 1 ? 'cartão vence' : 'cartões vencem'} amanhã.`}</p>
            </>
          )}
          <p><Link to={`/flashcards/${deckId}/notas/nova`}>Adicionar notas</Link> · <Link to="/flashcards">Outros baralhos</Link></p>
        </div>
      )}

      {card && (
        <>
          <article className="card fc-face" aria-live="polite">
            <div className="fc-question"><Markdown>{card.question}</Markdown></div>
            {revealed && (
              <>
                <hr />
                <div className="fc-answer"><Markdown>{card.answer}</Markdown></div>
              </>
            )}
            {card.tags.length > 0 && (
              <div className="meta">{card.tags.map((tag) => <span key={tag} className="badge">{tag}</span>)}</div>
            )}
          </article>

          <div className="fc-buttons">
            {!revealed ? (
              <button type="button" className="btn primary fc-reveal" onClick={() => setRevealed(true)}>
                Mostrar resposta
              </button>
            ) : (
              RATINGS.map((rating) => (
                <button key={rating} type="button" className={`btn fc-rate fc-rate-${rating}`} disabled={busy}
                  onClick={() => void answer(rating)}>
                  <span className="fc-rate-interval">{card.intervals[String(rating) as '1' | '2' | '3' | '4']}</span>
                  <span>{RATING_LABELS[rating]}</span>
                </button>
              ))
            )}
          </div>
          <p className="muted small fc-hint">Atalhos: espaço mostra a resposta; 1 a 4 respondem.</p>
          <Link to={`/flashcards/notas/${card.note_id}`} className="small">Editar esta nota</Link>
        </>
      )}
    </section>
  )
}
