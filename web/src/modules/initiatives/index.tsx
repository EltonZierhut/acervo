import type { OrganizerModule } from '../types'
import { ContextsPage } from './pages/ContextsPage'
import { InitiativeRoute } from './pages/InitiativePage'
import { InitiativesPage } from './pages/InitiativesPage'
import { NewInitiativePage } from './pages/NewInitiativePage'

export const initiativesModule: OrganizerModule = {
  key: 'initiatives',
  name: 'Iniciativas',
  icon: '◆',
  path: '/iniciativas',
  routes: [
    { index: true, element: <InitiativesPage /> },
    { path: 'nova', element: <NewInitiativePage /> },
    { path: 'contextos', element: <ContextsPage /> },
    { path: ':id', element: <InitiativeRoute /> },
  ],
}

