import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useAsync, useDebounce } from '../../../core/hooks'
import { codesApi, LANGUAGES } from '../api'
import { CodeBlock } from '../components/CodeBlock'
import { SubNav } from '../components/SubNav'
import { Tags } from '../components/Tags'

export function SnippetsPage() {
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const language = params.get('language') ?? ''
  const tag = params.get('tag') ?? ''
  const page = Number(params.get('page') ?? 1)
  const q = useDebounce(query.trim(), 300)

  const { data, loading, error } = useAsync(
    () => codesApi.listSnippets({ q, language, tag, page }),
    [q, language, tag, page],
  )

  const updateParam = (key: string, value: string) => {
    const next = new URLSearchParams(params)
    if (value) next.set(key, value)
    else next.delete(key)
    if (key !== 'page') next.delete('page')
    setParams(next, { replace: true })
  }

  return (
    <section>
      <header className="page-header">
        <h1>Códigos</h1>
        <Link to="/codigos/novo" className="btn primary">+ Novo código</Link>
      </header>
      <SubNav />

      <div className="filters">
        <input
          className="search"
          type="search"
          autoFocus
          placeholder='Buscar por título, tags ou trecho do código (ex.: useDebounce, "pg_dump", react -vue)'
          value={query}
          onChange={(e) => {
            setQuery(e.target.value)
            updateParam('q', e.target.value.trim())
          }}
        />
        <select value={language} onChange={(e) => updateParam('language', e.target.value)}>
          <option value="">Todas as linguagens</option>
          {LANGUAGES.map((lang) => (
            <option key={lang} value={lang}>{lang}</option>
          ))}
        </select>
        {tag && (
          <button className="chip" onClick={() => updateParam('tag', '')}>#{tag} ✕</button>
        )}
      </div>

      {error && <p className="error">{error}</p>}
      {loading && !data && <p className="muted">Carregando…</p>}

      {data && (
        <>
          <p className="muted small">
            {data.meta.total} {data.meta.total === 1 ? 'resultado' : 'resultados'}
          </p>
          {data.data.length === 0 && (
            <div className="empty">
              {q || language || tag ? 'Nada encontrado com esses filtros.' : 'Nenhum código salvo ainda.'}
            </div>
          )}
          <ul className="card-list">
            {data.data.map((snippet) => (
              <li key={snippet.id} className="card">
                <Link to={`/codigos/${snippet.id}`} className="card-title">{snippet.title}</Link>
                <div className="meta">
                  {snippet.language && <span className="badge">{snippet.language}</span>}
                  {snippet.project && (
                    <Link to={`/codigos/projetos/${snippet.project.id}`}>{snippet.project.name}</Link>
                  )}
                </div>
                {snippet.description && <p className="description">{snippet.description}</p>}
                <CodeBlock code={snippet.content} language={snippet.language} maxLines={8} />
                <Tags tags={snippet.tags} />
              </li>
            ))}
          </ul>
          {data.meta.total_pages > 1 && (
            <div className="pagination">
              <button disabled={page <= 1} onClick={() => updateParam('page', String(page - 1))}>Anterior</button>
              <span>{page} de {data.meta.total_pages}</span>
              <button disabled={page >= data.meta.total_pages} onClick={() => updateParam('page', String(page + 1))}>Próxima</button>
            </div>
          )}
        </>
      )}
    </section>
  )
}
