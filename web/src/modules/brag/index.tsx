import { TrophyIcon } from '../../core/icons'
import type { OrganizerModule } from '../types'
import { BragPage } from './pages/BragPage'
import { EditEntryPage, NewEntryPage } from './pages/EntryPage'

export const bragModule: OrganizerModule = {
  key: 'brag',
  name: 'Brag document',
  icon: <TrophyIcon />,
  path: '/brag',
  routes: [
    { index: true, element: <BragPage /> },
    { path: 'novo', element: <NewEntryPage /> },
    { path: ':id', element: <EditEntryPage /> },
  ],
}
