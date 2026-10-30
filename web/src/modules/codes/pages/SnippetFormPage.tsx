import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { useAsync } from '../../../core/hooks'
import { codesApi, LANGUAGES } from '../api'
import type { SnippetInput } from '../types'

const empty: SnippetInput = { title: '', description: '', language: '', content: '', project_id: null, tags: '' }

export function SnippetFormPage() {
  const params = useParams()
  const [searchParams] = useSearchParams()
  const id = params.id ? Number(params.id) : null
  const navigate = useNavigate()

  const [form, setForm] = useState<SnippetInput>({
    ...empty,
    project_id: searchParams.get('project_id') ? Number(searchParams.get('project_id')) : null,
  })
  const [errors, setErrors] = useState<string[]>([])
  const [saving, setSaving] = useState(false)
  const { data: projects } = useAsync(() => codesApi.listProjects(), [])

  useEffect(() => {
    if (!id) return
    codesApi.getSnippet(id).then((s) =>
      setForm({
        title: s.title,
        description: s.description ?? '',
        language: s.language ?? '',
        content: s.content,
        project_id: s.project_id,
        tags: s.tags.join(', '),
      }),
    )
  }, [id])

  const set = <K extends keyof SnippetInput>(key: K, value: SnippetInput[K]) =>
    setForm((current) => ({ ...current, [key]: value }))

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setErrors([])
    try {
      const saved = id ? await codesApi.updateSnippet(id, form) : await codesApi.createSnippet(form)
      navigate(`/codigos/${saved.id}`)
    } catch (err) {
      setErrors(err instanceof ApiError ? err.errors : [String(err)])
    } finally {
      setSaving(false)
    }
  }

  return (
    <section>
      <Link to={id ? `/codigos/${id}` : '/codigos'} className="back">← Voltar</Link>
      <h1>{id ? 'Editar código' : 'Novo código'}</h1>

      <form className="form" onSubmit={submit}>
        {errors.length > 0 && (
          <ul className="error">{errors.map((e) => <li key={e}>{e}</li>)}</ul>
        )}
        <label>
          Título
          <input value={form.title} onChange={(e) => set('title', e.target.value)} required />
        </label>
        <div className="row">
          <label>
            Linguagem
            <select value={form.language ?? ''} onChange={(e) => set('language', e.target.value)}>
              <option value="">—</option>
              {LANGUAGES.map((lang) => <option key={lang} value={lang}>{lang}</option>)}
            </select>
          </label>
          <label>
            Projeto
            <select
              value={form.project_id ?? ''}
              onChange={(e) => set('project_id', e.target.value ? Number(e.target.value) : null)}
            >
              <option value="">Sem projeto</option>
              {projects?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </label>
        </div>
        <label>
          Tags <span className="muted small">(separadas por vírgula)</span>
          <input value={form.tags} onChange={(e) => set('tags', e.target.value)} placeholder="react, hooks" />
        </label>
        <label>
          Descrição
          <textarea rows={2} value={form.description ?? ''} onChange={(e) => set('description', e.target.value)} />
        </label>
        <label>
          Código
          <textarea
            className="code-input"
            rows={16}
            spellCheck={false}
            value={form.content}
            onChange={(e) => set('content', e.target.value)}
            onKeyDown={(e) => {
              // Tab insere 2 espaços em vez de sair do campo
              if (e.key !== 'Tab') return
              e.preventDefault()
              const el = e.currentTarget
              const { selectionStart: start, selectionEnd: end } = el
              set('content', form.content.slice(0, start) + '  ' + form.content.slice(end))
              requestAnimationFrame(() => el.setSelectionRange(start + 2, start + 2))
            }}
            required
          />
        </label>
        <button className="btn primary" disabled={saving}>{saving ? 'Salvando…' : 'Salvar'}</button>
      </form>
    </section>
  )
}
