import { SproutIcon } from '../../core/icons'
import type { OrganizerModule } from '../types'
import { MeetingPage } from './pages/MeetingPage'
import { MentorshipPage } from './pages/MentorshipPage'
import { MentorshipsPage } from './pages/MentorshipsPage'
import { NewMentorshipPage } from './pages/NewMentorshipPage'

export const mentoringModule: OrganizerModule = {
  key: 'mentoring',
  name: 'Mentoria',
  icon: <SproutIcon />,
  path: '/mentoria',
  routes: [
    { index: true, element: <MentorshipsPage /> },
    { path: 'nova', element: <NewMentorshipPage /> },
    { path: 'encontros/:id', element: <MeetingPage /> },
    { path: ':id', element: <MentorshipPage /> },
  ],
}
