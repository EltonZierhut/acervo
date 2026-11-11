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

export const CardsIcon = () => (
  <Icon><rect x="3" y="7" width="13" height="14" rx="2" /><path d="M8 3h11a2 2 0 0 1 2 2v12" /><path d="M7 14h5" /></Icon>
)

export const TargetIcon = () => (
  <Icon><circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r=".6" /></Icon>
)

export const UserIcon = () => (
  <Icon><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7" /></Icon>
)

export const SproutIcon = () => (
  <Icon><path d="M12 21v-9" /><path d="M12 12C12 8 9 5 4 5c0 4 3 7 8 7z" /><path d="M12 14c0-3 2.5-5.5 7-5.5 0 3.5-2.5 5.5-7 5.5z" /></Icon>
)
