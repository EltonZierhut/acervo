import { NavLink } from 'react-router-dom'

export function SubNav() {
  return (
    <div className="subnav">
      <NavLink to="/codigos" end>Códigos</NavLink>
      <NavLink to="/codigos/projetos">Projetos</NavLink>
    </div>
  )
}
