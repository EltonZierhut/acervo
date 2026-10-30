import { NavLink, Outlet } from 'react-router-dom'
import { modules } from '../modules'

export function Layout() {
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
        <p className="sidebar-hint">Novos módulos aparecem aqui.</p>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  )
}
