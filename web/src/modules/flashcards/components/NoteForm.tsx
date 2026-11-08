import { useState } from 'react'
import type { FormEvent } from 'react'
import type { Deck, Note, NoteInput, NoteType } from '../types'
import { Markdown } from './Markdown'

interface Props {
  note?: Note
  decks?: Deck[] // na edição, permite mover a nota de baralho
  noteType?: NoteType
  submitLabel: string
  onSubmit: (input: NoteInput) => Promise<void>
}

interface FormState {
  note_type: NoteType
  front: string
  back: string
  tags: string
  deck_id: number | undefined
}

function toForm(note?: Note, noteType: NoteType = 'basic'): FormState {
  return {
    note_type: note?.note_type ?? noteType,
    front: note?.front ?? '',
    back: note?.back ?? '',
    tags: note?.tags.join(', ') ?? '',
    deck_id: note?.deck_id,
  }
}

function Side({ id, label, value, preview, onChange }: {
  id: string
  label: string
  value: string
  preview: boolean
  onChange: (value: string) => void
}) {
  return (
    <div className="label-block">
      <label htmlFor={id}>{label}</label>
      {preview ? (
        <div className="markdown-preview">
          {value.trim() ? <Markdown>{value}</Markdown> : <p className="muted">Nada para visualizar.</p>}
        </div>
      ) : (
        <textarea id={id} rows={4} value={value} onChange={(e) => onChange(e.target.value)} required />
      )}
    </div>
  )
}

export function NoteForm({ note, decks, noteType, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<FormState>(() => toForm(note, noteType))
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
      if (!note) setForm(toForm(undefined, form.note_type)) // pronta para a próxima, no mesmo tipo
      setPreview(false)
    } catch (err) {
      setErrors(err instanceof Error ? [err.message] : ['Não foi possível salvar'])
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="form" onSubmit={submit}>
      <div className="row">
        <label>
          Tipo
          <select value={form.note_type} onChange={(e) => set('note_type', e.target.value as NoteType)}>
            <option value="basic">Básico (frente → verso)</option>
            <option value="basic_reversed">Básico + invertido (os dois sentidos)</option>
          </select>
        </label>
        {decks && (
          <label>
            Baralho
            <select value={form.deck_id} onChange={(e) => set('deck_id', Number(e.target.value))}>
              {decks.map((deck) => <option key={deck.id} value={deck.id}>{deck.name}</option>)}
            </select>
          </label>
        )}
      </div>

      <div className="label-line">
        <span className="muted small">Frente e verso aceitam Markdown: **negrito**, listas e `código`.</span>
        <button type="button" className="small-btn" onClick={() => setPreview((v) => !v)} aria-pressed={preview}>
          {preview ? 'Editar' : 'Visualizar'}
        </button>
      </div>

      <Side id="fc-front" label="Frente" value={form.front} preview={preview} onChange={(v) => set('front', v)} />
      <Side id="fc-back" label="Verso" value={form.back} preview={preview} onChange={(v) => set('back', v)} />

      <label>
        Tags
        <input value={form.tags} onChange={(e) => set('tags', e.target.value)} placeholder="separadas por vírgula" />
      </label>

      {errors.length > 0 && <p className="error">{errors.join(', ')}</p>}
      <button type="submit" className="btn primary" disabled={saving || !form.front.trim() || !form.back.trim()}>
        {saving ? 'Salvando…' : submitLabel}
      </button>
    </form>
  )
}
