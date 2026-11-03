import type { ReactNode } from 'react'

// Ícones em SVG embutido, sem biblioteca. Usam currentColor, então acompanham o tema.
function Icon({ children }: { children: ReactNode }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden focusable="false">
      {children}
    </svg>
  )
}

export const CodeIcon = () => (
  <Icon><path d="m8 7-5 5 5 5" /><path d="m16 7 5 5-5 5" /><path d="m14 4-4 16" /></Icon>
)

export const TrophyIcon = () => (
  <Icon><path d="M8 4h8v6a4 4 0 0 1-8 0z" /><path d="M8 6H4v1a4 4 0 0 0 4 4" /><path d="M16 6h4v1a4 4 0 0 1-4 4" /><path d="M12 14v4" /><path d="M8 20h8" /></Icon>
)

export const TargetIcon = () => (
  <Icon><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r=".6" /></Icon>
)

export const UserIcon = () => (
  <Icon><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7" /></Icon>
)
