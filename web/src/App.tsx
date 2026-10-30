import { createBrowserRouter, Navigate, RouterProvider } from 'react-router-dom'
import { Layout } from './core/Layout'
import { modules } from './modules'

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      { index: true, element: <Navigate to={modules[0].path} replace /> },
      ...modules.map((mod) => ({ path: mod.path, children: mod.routes })),
      { path: '*', element: <p className="muted">Página não encontrada.</p> },
    ],
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
