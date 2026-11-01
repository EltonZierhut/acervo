import { useState } from 'react'
import type { FormEvent } from 'react'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { entries, PRIORITY_LABELS, SECTION_LABELS, SECTIONS, STATUS_LABELS } from '../labels'
import type { Initiative, InitiativeInput, Section } from '../types'

interface Props {
  initiative?: Initiative
  submitLabel: string
  onSubmit: (input: InitiativeInput) => Promise<void>
}

function toInput(initiative?: Initiative): InitiativeInput {
  return {
    name: initiative?.name ?? '',
    description: initiative?.description ?? '',
    context_id: initiative?.context?.id ?? null,
    status: initiative?.status ?? 'planned',
    priority: initiative?.priority ?? 'medium',
    starts_on: initiative?.starts_on ?? null,
    due_on: initiative?.due_on ?? null,
    tags: initiative?.tags.join(', ') ?? '',
    sections: initiative?.sections ?? SECTIONS,
    github_repository: initiative?.github_repository ?? '',
  }
}

export function InitiativeForm({ initiative, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<InitiativeInput>(() => toInput(initiative))
  const [errors, setErrors] = useState<string[]>([])
  const [saving, setSaving] = useState(false)
  const contexts = useAsync(() => initiativesApi.listContexts(), [])

  const set = <K extends keyof InitiativeInput>(key: K, value: InitiativeInput[K]) =>
    setForm((current) => ({ ...current, [key]: value }))

  const toggleSection = (section: Section, on: boolean) =>
    set('sections', SECTIONS.filter((s) => (s === section ? on : form.sections.includes(s))))

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
        Nome
        <input value={form.name} onChange={(e) => set('name', e.target.value)} required maxLength={200} autoFocus={!initiative} />
      </label>

      <label>
        Descrição
        <textarea rows={4} value={form.description} onChange={(e) => set('description', e.target.value)} placeholder="Objetivo, contexto, links importantes…" />
      </label>

      <div className="row">
        <label>
          Contexto
          <select
            value={form.context_id ?? ''}
            onChange={(e) => set('context_id', e.target.value ? Number(e.target.value) : null)}
          >
            <option value="">Sem contexto</option>
            {contexts.data?.map((context) => (
              <option key={context.id} value={context.id}>{context.name}</option>
            ))}
          </select>
        </label>
        <label>
          Tags
          <input value={form.tags} onChange={(e) => set('tags', e.target.value)} placeholder="separadas por vírgula" />
        </label>
      </div>

      <div className="row">
        <label>
          Status
          <select value={form.status} onChange={(e) => set('status', e.target.value as InitiativeInput['status'])}>
            {entries(STATUS_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </label>
        <label>
          Prioridade
          <select value={form.priority} onChange={(e) => set('priority', e.target.value as InitiativeInput['priority'])}>
            {entries(PRIORITY_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </label>
      </div>

      <div className="row">
        <label>
          Início
          <input type="date" value={form.starts_on ?? ''} onChange={(e) => set('starts_on', e.target.value || null)} />
        </label>
        <label>
          Data-alvo
          <input type="date" value={form.due_on ?? ''} min={form.starts_on ?? undefined} onChange={(e) => set('due_on', e.target.value || null)} />
        </label>
      </div>

      <fieldset className="sections-field">
        <legend>Seções</legend>
        {SECTIONS.map((section) => (
          <label key={section} className="check">
            <input
              type="checkbox"
              checked={form.sections.includes(section)}
              onChange={(e) => toggleSection(section, e.target.checked)}
            />
            {SECTION_LABELS[section]}
          </label>
        ))}
        <span className="muted small">Desligar uma seção esconde a aba, sem apagar os dados.</span>
      </fieldset>

      <label>
        Repositório no GitHub
        <input
          value={form.github_repository}
          onChange={(e) => set('github_repository', e.target.value)}
          placeholder="dono/repositório ou endereço do GitHub (opcional)"
          maxLength={300}
        />
        <span className="muted small">Necessário só para enviar tarefas para a fila de IA.</span>
      </label>

      {errors.length > 0 && <p className="error">{errors.join(', ')}</p>}
      <button type="submit" className="btn primary" disabled={saving}>{saving ? 'Salvando…' : submitLabel}</button>
    </form>
  )
}
