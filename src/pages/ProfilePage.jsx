import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  User,
  Mail,
  Sun,
  Moon,
  LogOut,
  Save,
  Check,
  Target,
  BookOpen,
  Flame,
} from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import { useTheme } from '../hooks/useTheme'
import { useHabits } from '../hooks/useHabits'

export default function ProfilePage() {
  const { user, profile, signOut, updateProfile } = useAuth()
  const { isDark, toggleTheme } = useTheme()
  const { habits, completions, getBestStreak } = useHabits()

  const [fullName, setFullName] = useState(profile?.full_name || '')
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

  async function handleSave() {
    setSaving(true)
    await updateProfile({ full_name: fullName })
    setSaving(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const stats = [
    {
      icon: Target,
      label: 'Active Habits',
      value: habits.length,
      color: 'text-indigo-500',
      bg: 'bg-indigo-50 dark:bg-indigo-950/30',
    },
    {
      icon: BookOpen,
      label: 'Completions',
      value: completions.length,
      color: 'text-emerald-500',
      bg: 'bg-emerald-50 dark:bg-emerald-950/30',
    },
    {
      icon: Flame,
      label: 'Best Streak',
      value: `${getBestStreak()}d`,
      color: 'text-amber-500',
      bg: 'bg-amber-50 dark:bg-amber-950/30',
    },
  ]

  return (
    <div className="space-y-6 max-w-lg mx-auto">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-zinc-50">
          Profile
        </h1>
        <p className="text-sm text-slate-500 dark:text-zinc-400 mt-0.5">
          Manage your account and preferences
        </p>
      </div>

      {/* Avatar & Info */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="bento-card flex items-center gap-4"
      >
        <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-indigo-500/20">
          <span className="text-xl font-bold text-white">
            {(profile?.full_name || user?.email || '?')[0].toUpperCase()}
          </span>
        </div>
        <div className="min-w-0">
          <h2 className="text-base font-semibold text-slate-900 dark:text-zinc-50 truncate">
            {profile?.full_name || 'User'}
          </h2>
          <p className="text-sm text-slate-400 truncate">{user?.email}</p>
        </div>
      </motion.div>

      {/* Stats */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-3 gap-3"
      >
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="bento-card flex flex-col items-center text-center py-4"
          >
            <div className={`w-10 h-10 ${stat.bg} rounded-xl flex items-center justify-center mb-2`}>
              <stat.icon className={`w-5 h-5 ${stat.color}`} />
            </div>
            <p className="text-lg font-bold text-slate-900 dark:text-zinc-50">
              {stat.value}
            </p>
            <p className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">
              {stat.label}
            </p>
          </div>
        ))}
      </motion.div>

      {/* Edit Profile */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bento-card space-y-4"
      >
        <h3 className="text-sm font-semibold text-slate-700 dark:text-zinc-300">
          Edit Profile
        </h3>

        {/* Full Name */}
        <div>
          <label htmlFor="profile-name" className="block text-sm font-medium text-slate-600 dark:text-zinc-400 mb-1.5">
            Full Name
          </label>
          <div className="relative">
            <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              id="profile-name"
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-slate-50 dark:bg-zinc-800/50 border border-slate-200 dark:border-zinc-700 rounded-xl text-sm text-slate-900 dark:text-zinc-50 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all"
            />
          </div>
        </div>

        {/* Email (read-only) */}
        <div>
          <label className="block text-sm font-medium text-slate-600 dark:text-zinc-400 mb-1.5">
            Email
          </label>
          <div className="relative">
            <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="email"
              value={user?.email || ''}
              readOnly
              className="w-full pl-10 pr-4 py-2.5 bg-slate-100 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 rounded-xl text-sm text-slate-500 dark:text-zinc-400 cursor-not-allowed"
            />
          </div>
        </div>

        <motion.button
          whileTap={{ scale: 0.98 }}
          onClick={handleSave}
          disabled={saving}
          className="w-full flex items-center justify-center gap-2 py-2.5 bg-gradient-to-r from-indigo-500 to-indigo-600 hover:from-indigo-600 hover:to-indigo-700 text-white font-medium rounded-xl text-sm shadow-lg shadow-indigo-500/25 transition-all disabled:opacity-60"
        >
          {saving ? (
            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
          ) : saved ? (
            <>
              <Check className="w-4 h-4" />
              Saved!
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              Save Changes
            </>
          )}
        </motion.button>
      </motion.div>

      {/* Preferences */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="bento-card space-y-3"
      >
        <h3 className="text-sm font-semibold text-slate-700 dark:text-zinc-300">
          Preferences
        </h3>

        {/* Dark Mode Toggle */}
        <button
          onClick={toggleTheme}
          className="w-full flex items-center justify-between px-3 py-3 bg-slate-50 dark:bg-zinc-800/50 rounded-xl transition-colors hover:bg-slate-100 dark:hover:bg-zinc-800"
        >
          <div className="flex items-center gap-3">
            {isDark ? (
              <Moon className="w-5 h-5 text-indigo-400" />
            ) : (
              <Sun className="w-5 h-5 text-amber-500" />
            )}
            <span className="text-sm font-medium text-slate-700 dark:text-zinc-300">
              {isDark ? 'Dark Mode' : 'Light Mode'}
            </span>
          </div>
          <div
            className={`w-10 h-6 rounded-full p-0.5 transition-colors ${
              isDark ? 'bg-indigo-500' : 'bg-slate-300'
            }`}
          >
            <motion.div
              animate={{ x: isDark ? 16 : 0 }}
              transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              className="w-5 h-5 bg-white rounded-full shadow-sm"
            />
          </div>
        </button>
      </motion.div>

      {/* Sign Out */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
      >
        <button
          onClick={signOut}
          className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800/30 text-red-500 dark:text-red-400 font-medium rounded-xl text-sm hover:bg-red-100 dark:hover:bg-red-950/30 transition-all"
        >
          <LogOut className="w-4 h-4" />
          Sign Out
        </button>
      </motion.div>
    </div>
  )
}
