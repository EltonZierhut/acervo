// Abas da mentoria e o nome delas no endereço (?aba=questionario), em português.
export type TabKey = 'overview' | 'questions' | 'goals' | 'meetings' | 'actions' | 'assessment' | 'details'

export const TABS: { key: TabKey; slug: string; label: string }[] = [
  { key: 'overview', slug: 'visao-geral', label: 'Visão geral' },
  { key: 'questions', slug: 'questionario', label: 'Questionário' },
  { key: 'goals', slug: 'objetivos', label: 'Objetivos' },
  { key: 'meetings', slug: 'encontros', label: 'Encontros' },
  { key: 'actions', slug: 'acoes', label: 'Ações' },
  { key: 'assessment', slug: 'autoavaliacao', label: 'Autoavaliação' },
  { key: 'details', slug: 'detalhes', label: 'Detalhes' },
]

export const tabSlug = (key: TabKey) => TABS.find((tab) => tab.key === key)!.slug
