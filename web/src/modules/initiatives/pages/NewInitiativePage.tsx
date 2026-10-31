import { Link, useNavigate } from 'react-router-dom'
import { initiativesApi } from '../api'
import { InitiativeForm } from '../components/InitiativeForm'

export function NewInitiativePage() {
  const navigate = useNavigate()

  return (
    <section>
      <Link to="/iniciativas" className="back">← Iniciativas</Link>
      <h1>Nova iniciativa</h1>
      <InitiativeForm
        submitLabel="Criar iniciativa"
        onSubmit={async (input) => {
          const created = await initiativesApi.createInitiative(input)
          navigate(`/iniciativas/${created.id}`, { replace: true })
        }}
      />
    </section>
  )
}
