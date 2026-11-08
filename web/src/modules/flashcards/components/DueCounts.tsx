import type { DueCounts as Counts } from '../types'

// Novos (azul), em aprendizado (vermelho) e para revisar (verde), como no Anki.
export function DueCounts({ counts }: { counts: Counts }) {
  return (
    <span className="fc-counts" aria-label={`${counts.new} novos, ${counts.learning} em aprendizado, ${counts.review} para revisar`}>
      <span className="fc-new" title="Novos">{counts.new}</span>
      <span className="fc-learning" title="Em aprendizado">{counts.learning}</span>
      <span className="fc-review" title="Para revisar">{counts.review}</span>
    </span>
  )
}
