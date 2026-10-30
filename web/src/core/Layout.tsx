import { useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { modules } from '../modules'
import { useAuth } from './auth-context'

export function Layout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [leaving, setLeaving] = useState(false)

  const signOut = async () => {
    setLeaving(true)
    try {
      await logout()
      navigate('/login', { replace: true })
    } finally {
      setLeaving(false)
    }
  }

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">Acervo</div>
        <nav>
          {modules.map((mod) => (
            <NavLink key={mod.key} to={mod.path} className="nav-item">
              <span aria-hidden>{mod.icon}</span>
              {mod.name}
            </NavLink>
          ))}
        </nav>
        <div className="account">
          <span className="account-email" title={user?.email_address}>{user?.email_address}</span>
          <button type="button" className="btn small-btn" onClick={signOut} disabled={leaving}>
            {leaving ? 'Saindo…' : 'Sair'}
          </button>
        </div>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
