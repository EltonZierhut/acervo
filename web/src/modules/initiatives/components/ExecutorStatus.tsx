import { useEffect } from 'react'
import { useAsync } from '../../../core/hooks'
import { initiativesApi } from '../api'
import { timeAgo } from '../labels'

export function ExecutorStatus() {
  const status = useAsync(() => initiativesApi.executorStatus(), [])
  const reload = status.reload

  useEffect(() => {
    const timer = window.setInterval(reload, 30000)
    return () => window.clearInterval(timer)
  }, [reload])

  if (status.error) return <p className="error small">{status.error}</p>
  if (!status.data) return null
  const { configured, available, last_seen_at: lastSeen } = status.data

  if (available) return <p className="executor-status small"><span className="dot ok" /> Executor disponível</p>
  return (
    <p className="executor-status small">
      <span className="dot" /> Executor indisponível{lastSeen ? ` (visto ${timeAgo(lastSeen)})` : ''}.{' '}
      {configured
        ? 'As tarefas aguardam até ele ser aberto no seu computador.'
        : 'Ele ainda não foi configurado; veja docs/executor.md.'}
    </p>
  )
}
