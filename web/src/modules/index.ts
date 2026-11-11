import { bragModule } from './brag'
import { codesModule } from './codes'
import { flashcardsModule } from './flashcards'
import { initiativesModule } from './initiatives'
import { mentoringModule } from './mentoring'
import type { OrganizerModule } from './types'

// Para adicionar um módulo: crie src/modules/<nome>/index.tsx exportando
// um OrganizerModule e coloque-o nesta lista.
export const modules: OrganizerModule[] = [codesModule, initiativesModule, bragModule, flashcardsModule, mentoringModule]
