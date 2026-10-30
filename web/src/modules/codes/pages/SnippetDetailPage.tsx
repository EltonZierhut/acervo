import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAsync } from '../../../core/hooks'
import { codesApi } from '../api'
import { CodeBlock } from '../components/CodeBlock'
import { Tags } from '../components/Tags'

export function SnippetDetailPage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const { data: snippet, loading, error } = useAsync(() => codesApi.getSnippet(id), [id])

  const remove = async () => {
    if (!confirm('Excluir este código?')) return
    await codesApi.deleteSnippet(id)
    navigate('/codigos')
  }

  if (loading) return <p className="muted">Carregando…</p>
  if (error || !snippet) return <p className="error">{error ?? 'Não encontrado'}</p>

  return (
    <section>
      <Link to="/codigos" className="back">← Códigos</Link>
      <header className="page-header">
        <h1>{snippet.title}</h1>
        <div className="actions">
          <Link to={`/codigos/${id}/editar`} className="btn">Editar</Link>
          <button className="btn danger" onClick={remove}>Excluir</button>
        </div>
      </header>
      <div className="meta">
        {snippet.language && <span className="badge">{snippet.language}</span>}
        {snippet.project && <Link to={`/codigos/projetos/${snippet.project.id}`}>{snippet.project.name}</Link>}
        <span className="muted small">Atualizado em {new Date(snippet.updated_at).toLocaleString('pt-BR')}</span>
      </div>
      {snippet.description && <p className="description">{snippet.description}</p>}
      <CodeBlock code={snippet.content} language={snippet.language} copyable />
      <Tags tags={snippet.tags} />
    </section>
  )
}
