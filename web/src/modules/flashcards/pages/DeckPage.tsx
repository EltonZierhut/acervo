import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { STATE_LABELS, flashcardsApi } from '../api'
import { DueCounts } from '../components/DueCounts'
import { Markdown } from '../components/Markdown'
import type { Deck } from '../types'

function DeckSettings({ deck, onSaved }: { deck: Deck; onSaved: () => void }) {
  const navigate = useNavigate()
  const [form, setForm] = useState({
    name: deck.name,
    description: deck.description ?? '',
    new_per_day: String(deck.new_per_day),
    reviews_per_day: String(deck.reviews_per_day),
  })
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const set = (key: keyof typeof form, value: string) => setForm((current) => ({ ...current, [key]: value }))

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setError(null)
    try {
      await flashcardsApi.updateDeck(deck.id, {
        name: form.name,
        description: form.description,
        new_per_day: Number(form.new_per_day),
        reviews_per_day: Number(form.reviews_per_day),
      })
      onSaved()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar')
    } finally {
      setSaving(false)
    }
  }

  const remove = async () => {
    if (!window.confirm(`Apagar o baralho "${deck.name}" com todas as notas e o histórico de estudo?`)) return
    await flashcardsApi.deleteDeck(deck.id)
    navigate('/flashcards', { replace: true })
  }

  return (
    <details className="card fc-settings">
      <summary>Configurações do baralho</summary>
      <form className="form" onSubmit={submit}>
        <label>
          Nome
          <input value={form.name} onChange={(e) => set('name', e.target.value)} required maxLength={100} />
        </label>
        <label>
          Descrição
          <textarea rows={2} value={form.description} onChange={(e) => set('description', e.target.value)} />
        </label>
        <div className="row">
          <label>
            Novos por dia
            <input type="number" inputMode="numeric" min={0} max={9999} value={form.new_per_day}
              onChange={(e) => set('new_per_day', e.target.value)} required />
          </label>
          <label>
            Revisões por dia
            <input type="number" inputMode="numeric" min={0} max={9999} value={form.reviews_per_day}
              onChange={(e) => set('reviews_per_day', e.target.value)} required />
          </label>
        </div>
        {error && <p className="error">{error}</p>}
        <div className="fc-actions">
          <button type="submit" className="btn primary" disabled={saving || !form.name.trim()}>{saving ? 'Salvando…' : 'Salvar'}</button>
          <button type="button" className="btn danger" onClick={remove}>Apagar baralho</button>
        </div>
      </form>
    </details>
  )
}

export function DeckPage() {
  const deckId = Number(useParams().deckId)
  const deck = useAsync(() => flashcardsApi.getDeck(deckId), [deckId])
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const debounced = useDebounce(query.trim(), 300)
  const q = params.get('q') ?? ''
  const page = Number(params.get('page') ?? 1)

  useEffect(() => {
    if (debounced === q) return
    setParams((current) => {
      const next = new URLSearchParams(current)
      if (debounced) next.set('q', debounced)
      else next.delete('q')
      next.delete('page')
      return next
    }, { replace: true })
  }, [debounced, q, setParams])

  const notes = useAsync(() => flashcardsApi.listNotes(deckId, { q, page }), [deckId, q, page])
  const goTo = (target: number) => setParams((current) => {
    const next = new URLSearchParams(current)
    next.set('page', String(target))
    return next
  })

  if (deck.error) {
    return (
      <section>
        <Link to="/flashcards" className="back">← Flashcards</Link>
        <p className="error">{deck.error}</p>
      </section>
    )
  }

  const pending = deck.data ? deck.data.due.new + deck.data.due.learning + deck.data.due.review : 0

  return (
    <section>
      <Link to="/flashcards" className="back">← Flashcards</Link>
      {deck.loading && !deck.data && <p className="muted">Carregando…</p>}
      {deck.data && (
        <>
          <header className="page-header">
            <h1 className="fc-deck-name">{deck.data.name}</h1>
            <Link to={`/flashcards/${deckId}/notas/nova`} className="btn">+ Nota</Link>
          </header>
          {deck.data.description && <p className="muted">{deck.data.description}</p>}

          <div className="card fc-study-box">
            <div>
              <DueCounts counts={deck.data.due} />
              <p className="muted small">{pending === 0 ? 'Nada para estudar agora.' : 'Novos · aprendendo · para revisar hoje'}</p>
            </div>
            {pending > 0 && <Link to={`/flashcards/${deckId}/estudar`} className="btn primary">Estudar agora</Link>}
          </div>

          <DeckSettings key={deck.data.updated_at} deck={deck.data} onSaved={deck.reload} />
        </>
      )}

      <div className="filters">
        <input className="search" type="search" aria-label="Buscar notas" placeholder="Buscar na frente, no verso ou nas tags…"
          value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>

      {notes.error && <p className="error">{notes.error}</p>}
      {notes.loading && !notes.data && <p className="muted">Carregando…</p>}
      {notes.data && notes.data.data.length === 0 && (
        <div className="empty">{q ? 'Nada encontrado.' : 'Nenhuma nota neste baralho ainda.'}</div>
      )}

      <ul className="card-list">
        {notes.data?.data.map((note) => (
          <li key={note.id} className="card">
            <Link to={`/flashcards/notas/${note.id}`} className="fc-note-link">
              <div className="clamp fc-preview"><Markdown>{note.front}</Markdown></div>
            </Link>
            <div className="clamp muted fc-preview"><Markdown>{note.back}</Markdown></div>
            <div className="meta">
              {note.suspended && <span className="chip">Suspensa</span>}
              {note.note_type === 'basic_reversed' && <span className="muted small">Frente e verso</span>}
              {!note.suspended && note.cards.map((card) => (
                <span key={card.id} className={`fc-state fc-state-${card.state}`}>{STATE_LABELS[card.state]}</span>
              ))}
              {note.tags.map((tag) => <span key={tag} className="badge">{tag}</span>)}
            </div>
          </li>
        ))}
      </ul>

      {notes.data && notes.data.meta.total_pages > 1 && (
        <div className="pager">
          <button type="button" disabled={page <= 1} onClick={() => goTo(page - 1)}>Anterior</button>
          <span className="muted small">Página {page} de {notes.data.meta.total_pages}</span>
          <button type="button" disabled={page >= notes.data.meta.total_pages} onClick={() => goTo(page + 1)}>Próxima</button>
        </div>
      )}
    </section>
  )
}
