import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { useAsync, useDebounce } from '../../../core/hooks'
import { codesApi } from '../api'
import { SubNav } from '../components/SubNav'
import { Tags } from '../components/Tags'
import type { ProjectInput } from '../types'

const empty: ProjectInput = { name: '', description: '', repository_url: '', tags: '' }

export function ProjectsPage() {
  const [query, setQuery] = useState('')
  const q = useDebounce(query.trim())
  const { data: projects, loading, error, reload } = useAsync(() => codesApi.listProjects(q), [q])

  const [form, setForm] = useState<ProjectInput>(empty)
  const [showForm, setShowForm] = useState(false)
  const [errors, setErrors] = useState<string[]>([])

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    try {
      await codesApi.createProject(form)
      setForm(empty)
      setShowForm(false)
      setErrors([])
      reload()
    } catch (err) {
      setErrors(err instanceof ApiError ? err.errors : [String(err)])
    }
  }

  return (
    <section>
      <header className="page-header">
        <h1>Projetos</h1>
        <button className="btn primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? 'Cancelar' : '+ Novo projeto'}
        </button>
      </header>
      <SubNav />

      {showForm && (
        <form className="form card" onSubmit={submit}>
          {errors.length > 0 && <ul className="error">{errors.map((e) => <li key={e}>{e}</li>)}</ul>}
          <label>
            Nome
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          </label>
          <label>
            URL do repositório
            <input
              value={form.repository_url ?? ''}
              placeholder="https://github.com/…"
              onChange={(e) => setForm({ ...form, repository_url: e.target.value })}
            />
          </label>
          <label>
            Tags
            <input value={form.tags} onChange={(e) => setForm({ ...form, tags: e.target.value })} />
          </label>
          <label>
            Descrição e anotações
            <textarea rows={4} value={form.description ?? ''} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          </label>
          <button className="btn primary">Criar projeto</button>
        </form>
      )}

      <div className="filters">
        <input className="search" type="search" placeholder="Buscar projetos" value={query} onChange={(e) => setQuery(e.target.value)} />
      </div>

      {error && <p className="error">{error}</p>}
      {loading && !projects && <p className="muted">Carregando…</p>}
      {projects?.length === 0 && <div className="empty">Nenhum projeto encontrado.</div>}

      <ul className="card-list grid">
        {projects?.map((project) => (
          <li key={project.id} className="card">
            <Link to={`/codigos/projetos/${project.id}`} className="card-title">{project.name}</Link>
            <p className="muted small">{project.snippets_count ?? 0} código(s)</p>
            {project.description && <p className="description clamp">{project.description}</p>}
            <Tags tags={project.tags} />
          </li>
        ))}
      </ul>
    </section>
  )
}
