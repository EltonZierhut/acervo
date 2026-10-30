import { createBrowserRouter, Navigate, Outlet, RouterProvider } from 'react-router-dom'
import { AuthProvider, RequireAuth } from './core/auth'
import { Layout } from './core/Layout'
import { LoginPage } from './core/LoginPage'
import { modules } from './modules'

// AuthProvider fica dentro do router porque usa useNavigate/useLocation.
function Root() {
  return (
    <AuthProvider>
      <Outlet />
    </AuthProvider>
  )
}

const router = createBrowserRouter([
  {
    element: <Root />,
    children: [
      { path: '/login', element: <LoginPage /> },
      {
        path: '/',
        element: (
          <RequireAuth>
            <Layout />
          </RequireAuth>
        ),
        children: [
          { index: true, element: <Navigate to={modules[0].path} replace /> },
          ...modules.map((mod) => ({ path: mod.path, children: mod.routes })),
          { path: '*', element: <p className="muted">Página não encontrada.</p> },
        ],
      },
    ],
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
