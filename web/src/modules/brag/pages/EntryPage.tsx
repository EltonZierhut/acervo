import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { bragApi } from '../api'
import { EntryForm } from '../components/EntryForm'

export function NewEntryPage() {
  const navigate = useNavigate()
  return (
    <section>
      <Link to="/brag" className="back">← Brag document</Link>
      <h1>Nova conquista</h1>
      <EntryForm submitLabel="Registrar" onSubmit={async (input) => {
        await bragApi.createEntry(input)
        navigate('/brag', { replace: true })
      }} />
    </section>
  )
}

export function EditEntryPage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const entry = useAsync(() => bragApi.getEntry(id), [id])

  const remove = async () => {
    if (!window.confirm('Apagar esta conquista?')) return
    await bragApi.deleteEntry(id)
    navigate('/brag', { replace: true })
  }

  return (
    <section>
      <Link to="/brag" className="back">← Brag document</Link>
      <header className="page-header">
        <h1>Editar conquista</h1>
        {entry.data && <button type="button" className="btn danger" onClick={remove}>Apagar</button>}
      </header>
      {entry.error && <p className="error">{entry.error}</p>}
      {entry.loading && !entry.data && <p className="muted">Carregando…</p>}
      {entry.data && (
        <EntryForm entry={entry.data} submitLabel="Salvar" onSubmit={async (input) => {
          await bragApi.updateEntry(id, input)
          navigate('/brag')
        }} />
      )}
    </section>
  )
}
