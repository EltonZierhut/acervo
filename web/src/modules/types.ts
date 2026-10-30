import type { RouteObject } from 'react-router-dom'

// Contrato que todo módulo do Acervo segue.
export interface OrganizerModule {
  key: string // igual à chave em api/config/modules.yml
  name: string
  icon: string
  path: string // prefixo das rotas, ex.: "/codigos"
  routes: RouteObject[] // rotas relativas ao path
}
