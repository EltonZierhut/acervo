import { useState } from 'react'
import { useAsync } from '../../../core/hooks'
import { mentoringApi } from '../api'
import { ActionItemList } from '../components/ActionItemList'
import type { Mentorship } from '../types'

type Filter = 'open' | 'done' | 'all'
const FILTERS: { value: Filter; label: string }[] = [
  { value: 'open', label: 'Abertas' },
  { value: 'done', label: 'Concluídas' },
  { value: 'all', label: 'Todas' },
]

export function ActionItemsTab({ mentorship }: { mentorship: Mentorship }) {
  const [filter, setFilter] = useState<Filter>('open')
  const list = useAsync(
    () => mentoringApi.listActionItems(mentorship.id, filter === 'all' ? {} : { status: filter }),
    [mentorship.id, filter],
  )
  const goals = useAsync(() => mentoringApi.listGoals(mentorship.id), [mentorship.id])

  return (
    <div>
      <div className="filters mt-segmented" role="group" aria-label="Mostrar ações">
        {FILTERS.map((f) => (
          <button key={f.value} type="button" className={`btn${filter === f.value ? ' primary' : ''}`} aria-pressed={filter === f.value}
            onClick={() => setFilter(f.value)}>{f.label}</button>
        ))}
      </div>
      {list.error && <p className="error">{list.error}</p>}
      {list.loading && !list.data && <p className="muted">Carregando…</p>}
      {list.data && (
        <ActionItemList mentorshipId={mentorship.id} items={list.data.data} goals={goals.data?.data ?? []} onChanged={list.reload} />
      )}
    </div>
  )
}
