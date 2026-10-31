import type { OrganizerModule } from '../types'
import { NotesPage } from './pages/NotesPage'

export const codesModule: OrganizerModule = {
  key: 'codes',
  name: 'Códigos',
  icon: '</>',
  path: '/codigos',
  // Rota única: ao criar, a URL vai de /codigos/novo para /codigos/:id sem desmontar o editor.
  routes: [{ path: ':id?', element: <NotesPage /> }],
}
