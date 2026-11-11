import { Link, useNavigate } from 'react-router-dom'
import { mentoringApi } from '../api'
import { MentorshipForm } from '../components/MentorshipForm'

export function NewMentorshipPage() {
  const navigate = useNavigate()
  return (
    <section>
      <Link to="/mentoria" className="back">← Mentoria</Link>
      <h1>Nova mentoria</h1>
      <MentorshipForm submitLabel="Criar e ir para o questionário" onSubmit={async (input, suggested) => {
        const mentorship = await mentoringApi.createMentorship(input, suggested)
        navigate(`/mentoria/${mentorship.id}?aba=questionario`, { replace: true })
      }} />
    </section>
  )
}
