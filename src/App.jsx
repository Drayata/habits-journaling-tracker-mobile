import { createBrowserRouter, RouterProvider } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import DashboardPage from './pages/DashboardPage'
import HabitsPage from './pages/HabitsPage'
import JournalPage from './pages/JournalPage'
import StatsPage from './pages/StatsPage'
import ProfilePage from './pages/ProfilePage'

const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/register',
    element: <RegisterPage />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'habits', element: <HabitsPage /> },
      { path: 'journal', element: <JournalPage /> },
      { path: 'stats', element: <StatsPage /> },
      { path: 'profile', element: <ProfilePage /> },
    ],
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
