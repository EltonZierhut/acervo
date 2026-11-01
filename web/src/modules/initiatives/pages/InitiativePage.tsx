import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { ApiError } from '../../../core/api'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { ContextBadge } from '../components/ContextBadge'
import { InitiativeForm } from '../components/InitiativeForm'
import { MilestoneList } from '../components/MilestoneList'
import { ProgressBar } from '../components/ProgressBar'
import { RepositoryField } from '../components/RepositoryField'
import { TaskList } from '../components/TaskList'
import { formatDate, isOverdue, PRIORITY_LABELS, SECTION_LABELS, STATUS_LABELS } from '../labels'
import type { Initiative, Milestone, Section } from '../types'

// Abas no endereço (?aba=tarefas), em português.
const TAB_SLUGS: Record<Section | 'details', string> = { tasks: 'tarefas', milestones: 'marcos', details: 'detalhes' }

export function InitiativePage() {
  const { id: rawId } = useParams()
  const id = Number(rawId)
  const validId = Number.isInteger(id) && id > 0
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()

  const [initiative, setInitiative] = useState<Initiative | null>(null)
  const [loadError, setLoadError] = useState<{ status: number; message: string } | null>(null)
  const [saved, setSaved] = useState(false)

  const loadInitiative = useCallback(() => {
    if (!validId) return
    initiativesApi
      .getInitiative(id)
      .then(setInitiative)
      .catch((err: Error) => setLoadError({ status: err instanceof ApiError ? err.status : 0, message: err.message }))
  }, [id, validId])

  useEffect(() => loadInitiative(), [loadInitiative])

  const usesMilestones = initiative?.sections.includes('milestones') ?? false
  const milestones = useAsync<Milestone[] | null>(
    () => (validId && usesMilestones ? initiativesApi.listMilestones(id) : Promise.resolve(null)),
    [id, validId, usesMilestones],
  )
  const reloadMilestones = milestones.reload

  // Tarefas e marcos mudam o progresso da iniciativa e dos marcos.
  const onChanged = useCallback(() => {
    loadInitiative()
    reloadMilestones()
  }, [loadInitiative, reloadMilestones])

  if (!validId || loadError?.status === 404) {
    return (
      <div className="empty">
        <p>Iniciativa não encontrada.</p>
        <Link to="/iniciativas">Voltar para a lista</Link>
      </div>
    )
  }
  if (loadError) return <p className="error">{loadError.message}</p>
  if (!initiative) return <p className="muted">Carregando…</p>

  const tabs: (Section | 'details')[] = [...initiative.sections, 'details']
  const current = tabs.find((tab) => TAB_SLUGS[tab] === params.get('aba')) ?? tabs[0]
  const overdue = isOverdue(initiative.due_on, initiative.status === 'done')

  const remove = async () => {
    if (!window.confirm(`Apagar "${initiative.name}" com todos os marcos e tarefas? Não dá para desfazer.`)) return
    await initiativesApi.deleteInitiative(initiative.id)
    navigate('/iniciativas', { replace: true })
  }

  return (
    <section className="initiative">
      <Link to="/iniciativas" className="back">← Iniciativas</Link>
      <header className="initiative-header">
        <h1>{initiative.name}</h1>
        <div className="meta">
          <span className={`status status-${initiative.status}`}>{STATUS_LABELS[initiative.status]}</span>
          <span className={`priority priority-${initiative.priority}`}>Prioridade {PRIORITY_LABELS[initiative.priority].toLowerCase()}</span>
          <ContextBadge context={initiative.context} />
          {initiative.starts_on && <span className="muted small">Início: {formatDate(initiative.starts_on)}</span>}
          {initiative.due_on && (
            <span className={overdue ? 'overdue small' : 'muted small'}>Alvo: {formatDate(initiative.due_on)}</span>
          )}
        </div>
        <ProgressBar progress={initiative.progress} />
        {initiative.description && <p className="description pre">{initiative.description}</p>}
      </header>

      <nav className="tabs" role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab}
            type="button"
            role="tab"
            aria-selected={tab === current}
            className={tab === current ? 'tab active' : 'tab'}
            onClick={() => {
              setSaved(false)
              setParams({ aba: TAB_SLUGS[tab] }, { replace: true })
            }}
          >
            {tab === 'details' ? 'Detalhes' : SECTION_LABELS[tab]}
          </button>
        ))}
      </nav>

      {initiative.sections.length === 0 && current === 'details' && (
        <p className="notice">Nenhuma seção ligada. Ligue Tarefas ou Marcos em "Seções", abaixo.</p>
      )}

      {current === 'tasks' && (
        <TaskList
          initiativeId={initiative.id}
          repository={initiative.repository_status === 'invalid' ? null : initiative.github_repository}
          milestones={usesMilestones ? milestones.data : null}
          onChanged={onChanged}
        />
      )}
      {current === 'milestones' && (
        <MilestoneList
          initiativeId={initiative.id}
          milestones={milestones.data}
          loading={milestones.loading}
          error={milestones.error}
          onChanged={onChanged}
        />
      )}
      {current === 'details' && (
        <>
          {saved && <p className="notice">Alterações salvas.</p>}
          <RepositoryField initiative={initiative} onChanged={setInitiative} />
          <InitiativeForm
            key={initiative.updated_at}
            initiative={initiative}
            submitLabel="Salvar alterações"
            onSubmit={async (input) => {
              setInitiative(await initiativesApi.updateInitiative(initiative.id, input))
              setSaved(true)
            }}
          />
          <div className="danger-zone">
            <button type="button" className="btn danger" onClick={remove}>Apagar iniciativa</button>
          </div>
        </>
      )}
    </section>
  )
}

// Trocar de iniciativa remonta a página, para não misturar dados de uma com a outra.
export function InitiativeRoute() {
  const { id } = useParams()
  return <InitiativePage key={id} />
}
