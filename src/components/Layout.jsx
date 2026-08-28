import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard,
  Target,
  BookOpen,
  UserCircle,
  BarChart3,
  Sun,
  Moon,
  Zap,
  LogOut,
} from 'lucide-react'
import { useTheme } from '../hooks/useTheme'
import { useAuth } from '../contexts/AuthContext'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/habits', icon: Target, label: 'Habits' },
  { to: '/journal', icon: BookOpen, label: 'Journal' },
  { to: '/stats', icon: BarChart3, label: 'Stats' },
  { to: '/profile', icon: UserCircle, label: 'Profile' },
]

function NavItem({ to, icon: Icon, label, isSidebar }) {
  return (
    <NavLink
      to={to}
      end={to === '/'}
      className={({ isActive }) =>
        `group flex items-center gap-3 transition-all duration-200 ${
          isSidebar
            ? `px-3 py-2.5 rounded-xl text-sm font-medium ${
                isActive
                  ? 'bg-zinc-100/80 text-zinc-900 dark:bg-indigo-500/10 dark:text-indigo-400'
                  : 'text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800/70 hover:text-zinc-900 dark:hover:text-zinc-200'
              }`
            : `flex-col items-center justify-center py-1 text-[11px] font-medium ${
                isActive
                  ? 'text-zinc-900 dark:text-indigo-400'
                  : 'text-zinc-500 dark:text-zinc-500'
              }`
        }`
      }
    >
      {({ isActive }) => (
        <>
          <div className="relative">
            <Icon className={`${isSidebar ? 'w-5 h-5' : 'w-5 h-5 mb-0.5'}`} />
            {isActive && !isSidebar && (
              <motion.div
                layoutId="nav-indicator"
                className="absolute -top-1.5 left-1/2 -translate-x-1/2 w-1 h-1 bg-indigo-500 rounded-full"
              />
            )}
          </div>
          <span>{label}</span>
        </>
      )}
    </NavLink>
  )
}

export default function Layout() {
  const { isDark, toggleTheme } = useTheme()
  const { signOut } = useAuth()
  const location = useLocation()

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 transition-colors duration-300">
      {/* ===== Desktop Sidebar (md+) ===== */}
      <aside className="hidden md:flex fixed left-0 top-0 bottom-0 w-64 flex-col bg-white dark:bg-zinc-900 border-r border-zinc-200/80 dark:border-zinc-800 z-30">
        {/* Logo */}
        <div className="flex items-center gap-2.5 px-5 py-5">
          <div className="w-9 h-9 bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-500/20">
            <Zap className="w-4.5 h-4.5 text-white" />
          </div>
          <span className="text-lg font-bold text-zinc-900 dark:text-zinc-50 tracking-tight">
            HabitFlow
          </span>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 py-2 space-y-1">
          {navItems.map((item) => (
            <NavItem key={item.to} {...item} isSidebar />
          ))}
        </nav>

        {/* Bottom section */}
        <div className="px-3 py-4 space-y-1 border-t border-zinc-200/80 dark:border-zinc-800">
          <button
            onClick={toggleTheme}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-zinc-500 dark:text-zinc-400 hover:bg-slate-100 dark:hover:bg-zinc-800/70 transition-all"
          >
            {isDark ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            {isDark ? 'Light Mode' : 'Dark Mode'}
          </button>
          <button
            onClick={signOut}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-red-500 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/20 transition-all"
          >
            <LogOut className="w-5 h-5" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* ===== Main Content ===== */}
      <main className="md:ml-64 min-h-screen pb-20 md:pb-0">
        <div className="max-w-6xl mx-auto px-4 md:px-6 py-6 md:py-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={location.pathname}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
            >
              <Outlet />
            </motion.div>
          </AnimatePresence>
        </div>
      </main>

      {/* ===== Mobile Bottom Nav (< md) ===== */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white/90 dark:bg-zinc-900/90 backdrop-blur-xl border-t border-zinc-200/80 dark:border-zinc-800 z-30">
        <div className="flex items-center justify-around px-1 py-2">
          {navItems.map((item) => (
            <NavItem key={item.to} {...item} isSidebar={false} />
          ))}
        </div>
      </nav>
    </div>
  )
}
