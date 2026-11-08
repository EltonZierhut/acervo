import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { flashcardsApi } from '../api'
import { DueCounts } from '../components/DueCounts'

function NewDeck({ onCreated }: { onCreated: () => void }) {
  const [name, setName] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    if (!name.trim()) return
    setSaving(true)
    setError(null)
    try {
      await flashcardsApi.createDeck({ name })
      setName('')
      onCreated()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível criar o baralho')
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="quick-add card" onSubmit={submit}>
      <div className="quick-add-row">
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Novo baralho (ex.: Inglês)"
          aria-label="Nome do novo baralho" maxLength={100} />
        <button type="submit" className="btn primary" disabled={saving || !name.trim()}>Criar</button>
      </div>
      {error && <p className="error">{error}</p>}
    </form>
  )
}

export function DecksPage() {
  const decks = useAsync(() => flashcardsApi.listDecks(), [])
  const total = decks.data?.reduce((sum, d) => sum + d.due.new + d.due.learning + d.due.review, 0) ?? 0

  return (
    <section>
      <header className="page-header">
        <h1>Flashcards</h1>
        {decks.data && decks.data.length > 0 && (
          <span className="muted small">{total === 0 ? 'Nada para hoje' : `${total} para estudar hoje`}</span>
        )}
      </header>

      <NewDeck onCreated={decks.reload} />

      {decks.error && <p className="error">{decks.error}</p>}
      {decks.loading && !decks.data && <p className="muted">Carregando…</p>}
      {decks.data && decks.data.length === 0 && (
        <div className="empty">Crie um baralho para começar a guardar seus cartões.</div>
      )}

      <ul className="card-list">
        {decks.data?.map((deck) => {
          const pending = deck.due.new + deck.due.learning + deck.due.review
          return (
            <li key={deck.id} className="card fc-deck">
              <div className="fc-deck-main">
                <Link to={`/flashcards/${deck.id}`} className="card-title">{deck.name}</Link>
                <div className="meta">
                  <DueCounts counts={deck.due} />
                  <span className="muted small">{deck.card_count} {deck.card_count === 1 ? 'cartão' : 'cartões'}</span>
                </div>
              </div>
              {pending > 0 && <Link to={`/flashcards/${deck.id}/estudar`} className="btn primary">Estudar</Link>}
            </li>
          )
        })}
      </ul>
    </section>
  )
}
