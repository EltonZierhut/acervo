import type { OrganizerModule } from '../types'
import { ProjectDetailPage } from './pages/ProjectDetailPage'
import { ProjectsPage } from './pages/ProjectsPage'
import { SnippetDetailPage } from './pages/SnippetDetailPage'
import { SnippetFormPage } from './pages/SnippetFormPage'
import { SnippetsPage } from './pages/SnippetsPage'

export const codesModule: OrganizerModule = {
  key: 'codes',
  name: 'Códigos',
  icon: '</>',
  path: '/codigos',
  routes: [
    { index: true, element: <SnippetsPage /> },
    { path: 'novo', element: <SnippetFormPage /> },
    { path: 'projetos', element: <ProjectsPage /> },
    { path: 'projetos/:id', element: <ProjectDetailPage /> },
    { path: ':id', element: <SnippetDetailPage /> },
    { path: ':id/editar', element: <SnippetFormPage /> },
  ],
}
