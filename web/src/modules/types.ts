import type { ReactNode } from 'react'
import type { RouteObject } from 'react-router-dom'

// Contrato que todo módulo do Acervo segue.
export interface OrganizerModule {
  key: string // igual à chave em api/config/modules.yml
  name: string
  icon: ReactNode // SVG embutido (ver core/icons.tsx); usa currentColor
  path: string // prefixo das rotas, ex.: "/codigos"
  routes: RouteObject[] // rotas relativas ao path
}
