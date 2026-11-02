import { useEffect, useRef, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { modules } from '../modules'
import { useAuth } from './auth-context'
import { UserIcon } from './icons'

// No computador a navegação é a barra lateral; no celular (até 720 px, ver index.css) é a barra
// inferior, com a conta num menu. As duas existem no DOM e o CSS mostra uma de cada vez.
export function Layout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [leaving, setLeaving] = useState(false)
  // O menu guarda a rota em que foi aberto: ao navegar, ele se fecha sozinho.
  const [menuPath, setMenuPath] = useState<string | null>(null)
  const menuOpen = menuPath === location.pathname
  const setMenuOpen = (open: boolean) => setMenuPath(open ? location.pathname : null)
  const menuRef = useRef<HTMLDivElement>(null)

  const signOut = async () => {
    setLeaving(true)
    try {
      await logout()
      navigate('/login', { replace: true })
    } finally {
      setLeaving(false)
    }
  }

  // Fecha o menu ao tocar fora dele ou com Esc.
  useEffect(() => {
    if (!menuOpen) return
    const onPointer = (event: PointerEvent) => {
      if (!menuRef.current?.contains(event.target as Node)) setMenuPath(null)
    }
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMenuPath(null)
    }
    document.addEventListener('pointerdown', onPointer)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('pointerdown', onPointer)
      document.removeEventListener('keydown', onKey)
    }
  }, [menuOpen])

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">Acervo</div>
        <nav aria-label="Módulos">
          {modules.map((mod) => (
            <NavLink key={mod.key} to={mod.path} className="nav-item">
              <span className="nav-icon" aria-hidden>{mod.icon}</span>
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
      <div className="bottom-bar" ref={menuRef}>
        {menuOpen && (
          <div className="account-menu" id="account-menu" role="menu">
            <span className="account-email" title={user?.email_address}>{user?.email_address}</span>
            <button type="button" role="menuitem" className="btn" onClick={signOut} disabled={leaving}>
              {leaving ? 'Saindo…' : 'Sair'}
            </button>
          </div>
        )}
        <nav className="bottom-nav" aria-label="Módulos">
          {modules.map((mod) => (
            <NavLink key={mod.key} to={mod.path} className="bottom-item">
              <span className="nav-icon" aria-hidden>{mod.icon}</span>
              <span className="bottom-label">{mod.name}</span>
            </NavLink>
          ))}
          <button
            type="button"
            className="bottom-item"
            aria-haspopup="menu"
            aria-expanded={menuOpen}
            aria-controls="account-menu"
            onClick={() => setMenuOpen(!menuOpen)}
          >
            <span className="nav-icon" aria-hidden><UserIcon /></span>
            <span className="bottom-label">Conta</span>
          </button>
        </nav>
      </div>
    </div>
  )
}
