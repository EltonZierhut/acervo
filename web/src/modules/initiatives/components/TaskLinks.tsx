import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import type { TaskLink } from '../types'

export function TaskLinks({ taskId, onChanged }: { taskId: number; onChanged: () => void }) {
  const links = useAsync(() => initiativesApi.listLinks(taskId), [taskId])
  const [url, setUrl] = useState('')
  const [title, setTitle] = useState('')
  const [error, setError] = useState<string | null>(null)

  const add = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    try {
      await initiativesApi.createLink(taskId, { url, title })
      setUrl('')
      setTitle('')
      links.reload()
      onChanged()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível salvar')
    }
  }

  const remove = async (link: TaskLink) => {
    if (!window.confirm(`Remover o link "${link.title ?? link.url}"?`)) return
    setError(null)
    try {
      await initiativesApi.deleteLink(link.id)
      links.reload()
      onChanged()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível remover')
    }
  }

  return (
    <section className="task-section">
      <h4>Links</h4>
      {links.error && <p className="error small">{links.error}</p>}
      {links.data && links.data.length > 0 && (
        <ul className="task-links">
          {links.data.map((link) => (
            <li key={link.id}>
              <a href={link.url} target="_blank" rel="noreferrer">{link.title ?? link.url}</a>
              <button type="button" className="link-button small" onClick={() => void remove(link)}>Remover</button>
            </li>
          ))}
        </ul>
      )}
      <form className="task-link-form" onSubmit={(e) => void add(e)}>
        <input type="url" value={url} onChange={(e) => setUrl(e.target.value)} placeholder="https://…" required maxLength={2048} aria-label="Endereço do link" />
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Título (opcional)" maxLength={200} aria-label="Título do link" />
        <button type="submit">Adicionar</button>
      </form>
      {error && <p className="error small">{error}</p>}
    </section>
  )
}
