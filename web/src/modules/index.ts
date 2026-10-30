import { codesModule } from './codes'
import type { OrganizerModule } from './types'

// Para adicionar um módulo: crie src/modules/<nome>/index.tsx exportando
// um OrganizerModule e coloque-o nesta lista.
export const modules: OrganizerModule[] = [codesModule]
