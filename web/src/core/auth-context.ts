import { createContext, useContext } from 'react'
import type { CurrentUser } from './api'

export type AuthStatus = 'loading' | 'authenticated' | 'anonymous'

export interface AuthContextValue {
  user: CurrentUser | null
  status: AuthStatus
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth precisa estar dentro de <AuthProvider>')
  return context
}

export function loginPath(next: string, expired = false) {
  const params = new URLSearchParams({ next })
  if (expired) params.set('expired', '1')
  return `/login?${params}`
}
