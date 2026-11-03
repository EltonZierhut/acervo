import { useState } from 'react'
import type { FormEvent } from 'react'
import { CATEGORY_SUGGESTIONS, today } from '../api'
import type { BragEntry, BragEntryInput } from '../types'
import { Markdown } from './Markdown'

interface Props {
  entry?: BragEntry
  submitLabel: string
  onSubmit: (input: BragEntryInput) => Promise<void>
}

type FormState = Required<BragEntryInput>

function toForm(entry?: BragEntry): FormState {
  return {
    title: entry?.title ?? '',
    achieved_on: entry?.achieved_on ?? today(),
    description: entry?.description ?? '',
    category: entry?.category ?? '',
    tags: entry?.tags.join(', ') ?? '',
    impact: entry?.impact ?? '',
    metrics: entry?.metrics ?? '',
    evidence_links: entry?.evidence_links.join('\n') ?? '',
    project: entry?.project ?? '',
  }
}

export function EntryForm({ entry, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<FormState>(() => toForm(entry))
  const [preview, setPreview] = useState(false)
  const [errors, setErrors] = useState<string[]>([])
  const [saving, setSaving] = useState(false)

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) =>
    setForm((current) => ({ ...current, [key]: value }))

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    setErrors([])
    try {
      await onSubmit(form)
    } catch (err) {
      setErrors(err instanceof Error ? [err.message] : ['Não foi possível salvar'])
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="form" onSubmit={submit}>
      <label>
        Título
        <input value={form.title} onChange={(e) => set('title', e.target.value)} required maxLength={200} autoFocus={!entry} />
      </label>

      <div className="row">
        <label>
          Data
          <input type="date" value={form.achieved_on} onChange={(e) => set('achieved_on', e.target.value)} required />
        </label>
        <label>
          Categoria
          <input value={form.category} onChange={(e) => set('category', e.target.value)} list="brag-categories" maxLength={100} />
          <datalist id="brag-categories">
            {CATEGORY_SUGGESTIONS.map((c) => <option key={c} value={c} />)}
          </datalist>
        </label>
      </div>

      <div className="label-block">
        <div className="label-line">
          <label htmlFor="brag-description">Descrição (Markdown)</label>
          <button type="button" className="small-btn" onClick={() => setPreview((v) => !v)} aria-pressed={preview}>
            {preview ? 'Editar' : 'Visualizar'}
          </button>
        </div>
        {preview ? (
          <div className="markdown-preview">
            {form.description.trim() ? <Markdown>{form.description}</Markdown> : <p className="muted">Nada para visualizar.</p>}
          </div>
        ) : (
          <textarea id="brag-description" rows={6} value={form.description} onChange={(e) => set('description', e.target.value)}
            placeholder="O que você fez? Aceita **negrito**, listas, links e `código`." />
        )}
      </div>

      <label>
        Impacto
        <textarea rows={2} value={form.impact} onChange={(e) => set('impact', e.target.value)} placeholder="O que mudou por causa disso?" />
      </label>

      <label>
        Métricas
        <textarea rows={2} value={form.metrics} onChange={(e) => set('metrics', e.target.value)} placeholder="Números: -30% de falhas, 12 pessoas treinadas…" />
      </label>

      <div className="row">
        <label>
          Projeto
          <input value={form.project} onChange={(e) => set('project', e.target.value)} maxLength={100} placeholder="Nome do projeto (opcional)" />
        </label>
        <label>
          Tags
          <input value={form.tags} onChange={(e) => set('tags', e.target.value)} placeholder="separadas por vírgula" />
        </label>
      </div>

      <label>
        Links de evidência
        <textarea rows={3} value={form.evidence_links} onChange={(e) => set('evidence_links', e.target.value)}
          placeholder={'Um endereço por linha\nhttps://…'} />
      </label>

      {errors.length > 0 && <p className="error">{errors.join(', ')}</p>}
      <button type="submit" className="btn primary" disabled={saving || !form.title.trim()}>{saving ? 'Salvando…' : submitLabel}</button>
    </form>
  )
}
