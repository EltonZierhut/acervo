import { useCallback, useEffect, useMemo, useState } from 'react'
import type { ReactNode } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { ApiError, authApi, setUnauthorizedHandler } from './api'
import type { CurrentUser } from './api'
import { AuthContext, loginPath, useAuth } from './auth-context'
import type { AuthStatus } from './auth-context'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<CurrentUser | null>(null)
  const [status, setStatus] = useState<AuthStatus>('loading')
  const navigate = useNavigate()
  const location = useLocation()

  // Descobre se já existe sessão ao abrir o app.
  useEffect(() => {
    authApi
      .current()
      .then((current) => {
        setUser(current)
        setStatus('authenticated')
      })
      .catch(() => {
        setUser(null)
        setStatus('anonymous')
      })
  }, [])

  // Sessão expirada no meio do uso: volta ao login lembrando onde estava.
  const currentPath = location.pathname + location.search
  useEffect(() => {
    setUnauthorizedHandler(() => {
      setUser(null)
      setStatus('anonymous')
      if (location.pathname !== '/login') navigate(loginPath(currentPath, true), { replace: true })
    })
    return () => setUnauthorizedHandler(null)
  }, [navigate, currentPath, location.pathname])

  const login = useCallback(async (email: string, password: string) => {
    const current = await authApi.login(email, password)
    setUser(current)
    setStatus('authenticated')
  }, [])

  const logout = useCallback(async () => {
    try {
      await authApi.logout()
    } catch (err) {
      // 401 aqui significa que a sessão já tinha acabado: o resultado é o mesmo.
      if (!(err instanceof ApiError && err.status === 401)) throw err
    }
    setUser(null)
    setStatus('anonymous')
  }, [])

  const value = useMemo(() => ({ user, status, login, logout }), [user, status, login, logout])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// Protege as rotas internas: sem login, leva para a tela de login.
export function RequireAuth({ children }: { children: ReactNode }) {
  const { status } = useAuth()
  const location = useLocation()

  if (status === 'loading') return <p className="muted centered">Carregando…</p>
  if (status === 'anonymous') {
    return <Navigate to={loginPath(location.pathname + location.search)} replace />
  }
  return <>{children}</>
}
