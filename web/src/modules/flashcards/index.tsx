import { CardsIcon } from '../../core/icons'
import type { OrganizerModule } from '../types'
import { DeckPage } from './pages/DeckPage'
import { DecksPage } from './pages/DecksPage'
import { EditNotePage, NewNotePage } from './pages/NotePage'
import { StudyPage } from './pages/StudyPage'

export const flashcardsModule: OrganizerModule = {
  key: 'flashcards',
  name: 'Flashcards',
  icon: <CardsIcon />,
  path: '/flashcards',
  routes: [
    { index: true, element: <DecksPage /> },
    { path: 'notas/:id', element: <EditNotePage /> },
    { path: ':deckId', element: <DeckPage /> },
    { path: ':deckId/estudar', element: <StudyPage /> },
    { path: ':deckId/notas/nova', element: <NewNotePage /> },
  ],
}
