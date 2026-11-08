import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { STATE_LABELS, flashcardsApi, formatDate } from '../api'
import { NoteForm } from '../components/NoteForm'

export function NewNotePage() {
  const deckId = Number(useParams().deckId)
  const deck = useAsync(() => flashcardsApi.getDeck(deckId), [deckId])
  const [saved, setSaved] = useState(0)

  return (
    <section>
      <Link to={`/flashcards/${deckId}`} className="back">← {deck.data?.name ?? 'Baralho'}</Link>
      <h1>Nova nota</h1>
      {deck.error && <p className="error">{deck.error}</p>}
      {saved > 0 && (
        <p className="muted small" role="status">
          {saved === 1 ? 'Nota salva.' : `${saved} notas salvas.`} Escreva a próxima ou volte ao baralho.
        </p>
      )}
      <NoteForm submitLabel="Salvar e criar outra" onSubmit={async (input) => {
        await flashcardsApi.createNote(deckId, input)
        setSaved((n) => n + 1)
      }} />
    </section>
  )
}

export function EditNotePage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const note = useAsync(() => flashcardsApi.getNote(id), [id])
  const decks = useAsync(() => flashcardsApi.listDecks(), [])
  const [message, setMessage] = useState<string | null>(null)

  const backTo = note.data ? `/flashcards/${note.data.deck_id}` : '/flashcards'

  const toggleSuspended = async () => {
    if (!note.data) return
    await flashcardsApi.updateNote(id, { suspended: !note.data.suspended })
    setMessage(note.data.suspended ? 'Nota reativada.' : 'Nota suspensa: os cartões saem do estudo.')
    note.reload()
  }

  const reset = async () => {
    if (!window.confirm('Recomeçar esta nota? Os cartões voltam a ser novos (o histórico fica guardado).')) return
    await flashcardsApi.resetNote(id)
    setMessage('Cartões voltaram a ser novos.')
    note.reload()
  }

  const remove = async () => {
    if (!window.confirm('Apagar esta nota e o histórico de estudo dela?')) return
    await flashcardsApi.deleteNote(id)
    navigate(backTo, { replace: true })
  }

  return (
    <section>
      <Link to={backTo} className="back">← Baralho</Link>
      <header className="page-header">
        <h1>Editar nota</h1>
      </header>
      {note.error && <p className="error">{note.error}</p>}
      {note.loading && !note.data && <p className="muted">Carregando…</p>}
      {note.data && decks.data && (
        <>
          <div className="meta">
            {note.data.cards.map((card) => (
              <span key={card.id} className="muted small">
                {card.ordinal === 0 ? 'Frente → verso' : 'Verso → frente'}: {STATE_LABELS[card.state]}
                {card.due_at && card.state === 'review' && `, vence em ${formatDate(card.due_at)}`}
                {card.lapses > 0 && `, ${card.lapses} ${card.lapses === 1 ? 'esquecimento' : 'esquecimentos'}`}
              </span>
            ))}
          </div>
          <NoteForm key={note.data.updated_at} note={note.data} decks={decks.data} submitLabel="Salvar"
            onSubmit={async (input) => {
              const updated = await flashcardsApi.updateNote(id, input)
              navigate(`/flashcards/${updated.deck_id}`)
            }} />
          {message && <p className="muted small" role="status">{message}</p>}
          <div className="fc-actions">
            <button type="button" className="btn" onClick={toggleSuspended}>{note.data.suspended ? 'Reativar' : 'Suspender'}</button>
            <button type="button" className="btn" onClick={reset}>Recomeçar</button>
            <button type="button" className="btn danger" onClick={remove}>Apagar</button>
          </div>
        </>
      )}
    </section>
  )
}
