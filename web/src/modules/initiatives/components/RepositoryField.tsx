import { useState } from 'react'
import { initiativesApi } from '../api'
import { formatDateTime, REPOSITORY_STATUS_LABELS } from '../labels'
import type { Initiative } from '../types'
import { ExecutorStatus } from './ExecutorStatus'

// Situação da conexão com o repositório. O campo em si fica no formulário de detalhes.
export function RepositoryField({ initiative, onChanged }: { initiative: Initiative; onChanged: (i: Initiative) => void }) {
  const [error, setError] = useState<string | null>(null)
  if (!initiative.github_repository) return null

  const verify = async () => {
    setError(null)
    try {
      onChanged(await initiativesApi.verifyRepository(initiative.id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível pedir a verificação')
    }
  }

  return (
    <div className="repository-status">
      <p>
        <a href={`https://github.com/${initiative.github_repository}`} target="_blank" rel="noreferrer">{initiative.github_repository}</a>{' '}
        <span className={`run-status repo-${initiative.repository_status}`}>{REPOSITORY_STATUS_LABELS[initiative.repository_status]}</span>
        {initiative.repository_checked_at && <span className="muted small"> · {formatDateTime(initiative.repository_checked_at)}</span>}
      </p>
      {initiative.repository_error && <p className="error small">{initiative.repository_error}</p>}
      {initiative.repository_status === 'unverified' && <ExecutorStatus />}
      {initiative.repository_status !== 'unverified' && <button type="button" onClick={() => void verify()}>Verificar de novo</button>}
      {error && <p className="error small">{error}</p>}
    </div>
  )
}
