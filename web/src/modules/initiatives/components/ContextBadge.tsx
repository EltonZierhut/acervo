import type { ContextRef } from '../types'

export function ContextBadge({ context }: { context: ContextRef | null }) {
  if (!context) return null
  return (
    <span className="context-badge">
      <span className="context-dot" style={{ background: context.color }} aria-hidden />
      {context.name}
    </span>
  )
}
