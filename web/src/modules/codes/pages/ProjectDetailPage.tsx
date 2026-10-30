import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { useAsync } from '../../../core/hooks'
import { codesApi } from '../api'
import { CodeBlock } from '../components/CodeBlock'
import { Tags } from '../components/Tags'
import type { Project, ProjectInput } from '../types'

const toInput = (p: Project): ProjectInput => ({
  name: p.name,
  description: p.description ?? '',
  repository_url: p.repository_url ?? '',
  tags: p.tags.join(', '),
})

export function ProjectDetailPage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const { data: project, loading, error, reload } = useAsync(() => codesApi.getProject(id), [id])
  const [editing, setEditing] = useState<ProjectInput | null>(null)
  const [errors, setErrors] = useState<string[]>([])

  const save = async (event: FormEvent) => {
    event.preventDefault()
    if (!editing) return
    try {
      await codesApi.updateProject(id, editing)
      setEditing(null)
      setErrors([])
      reload()
    } catch (err) {
      setErrors(err instanceof ApiError ? err.errors : [String(err)])
    }
  }

  const remove = async () => {
    if (!confirm('Excluir o projeto? Os códigos dele continuam salvos, só ficam sem projeto.')) return
    await codesApi.deleteProject(id)
    navigate('/codigos/projetos')
  }

  if (loading && !project) return <p className="muted">Carregando…</p>
  if (error || !project) return <p className="error">{error ?? 'Não encontrado'}</p>

  return (
    <section>
      <Link to="/codigos/projetos" className="back">← Projetos</Link>

      {editing ? (
        <form className="form card" onSubmit={save}>
          {errors.length > 0 && <ul className="error">{errors.map((e) => <li key={e}>{e}</li>)}</ul>}
          <label>Nome<input value={editing.name} onChange={(e) => setEditing({ ...editing, name: e.target.value })} required /></label>
          <label>URL do repositório<input value={editing.repository_url ?? ''} onChange={(e) => setEditing({ ...editing, repository_url: e.target.value })} /></label>
          <label>Tags<input value={editing.tags} onChange={(e) => setEditing({ ...editing, tags: e.target.value })} /></label>
          <label>Descrição e anotações<textarea rows={8} value={editing.description ?? ''} onChange={(e) => setEditing({ ...editing, description: e.target.value })} /></label>
          <div className="actions">
            <button className="btn primary">Salvar</button>
            <button type="button" className="btn" onClick={() => setEditing(null)}>Cancelar</button>
          </div>
        </form>
      ) : (
        <>
          <header className="page-header">
            <h1>{project.name}</h1>
            <div className="actions">
              <button className="btn" onClick={() => setEditing(toInput(project))}>Editar</button>
              <button className="btn danger" onClick={remove}>Excluir</button>
            </div>
          </header>
          {project.repository_url && (
            <a href={project.repository_url} target="_blank" rel="noreferrer">{project.repository_url}</a>
          )}
          {project.description && <p className="description pre">{project.description}</p>}
          <Tags tags={project.tags} />
        </>
      )}

      <header className="page-header section">
        <h2>Códigos do projeto</h2>
        <Link to={`/codigos/novo?project_id=${id}`} className="btn primary">+ Adicionar código</Link>
      </header>
      {project.snippets?.length === 0 && <div className="empty">Nenhum código neste projeto.</div>}
      <ul className="card-list">
        {project.snippets?.map((snippet) => (
          <li key={snippet.id} className="card">
            <Link to={`/codigos/${snippet.id}`} className="card-title">{snippet.title}</Link>
            {snippet.language && <span className="badge">{snippet.language}</span>}
            <CodeBlock code={snippet.content} language={snippet.language} maxLines={6} />
          </li>
        ))}
      </ul>
    </section>
  )
}
