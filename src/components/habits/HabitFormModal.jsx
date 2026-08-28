import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, Palette } from 'lucide-react'

const COLORS = [
  '#10b981', // emerald
  '#6366f1', // indigo
  '#f59e0b', // amber
  '#ef4444', // red
  '#8b5cf6', // violet
  '#06b6d4', // cyan
  '#ec4899', // pink
  '#f97316', // orange
]

export default function HabitFormModal({
  isOpen,
  onClose,
  onSubmit,
  editHabit = null,
}) {
  const [title, setTitle] = useState('')
  const [frequency, setFrequency] = useState('daily')
  const [colorHint, setColorHint] = useState('#10b981')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (editHabit) {
      setTitle(editHabit.title || '')
      setFrequency(editHabit.frequency || 'daily')
      setColorHint(editHabit.color_hint || '#10b981')
    } else {
      setTitle('')
      setFrequency('daily')
      setColorHint('#10b981')
    }
  }, [editHabit, isOpen])

  async function handleSubmit(e) {
    e.preventDefault()
    if (!title.trim()) return

    setLoading(true)
    await onSubmit({
      title: title.trim(),
      frequency,
      color_hint: colorHint,
    })
    setLoading(false)
    onClose()
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50"
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, y: 50, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 50, scale: 0.95 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed inset-x-4 bottom-4 md:inset-auto md:top-1/2 md:left-1/2 md:-translate-x-1/2 md:-translate-y-1/2 md:w-full md:max-w-md z-50"
          >
            <div className="bg-white dark:bg-zinc-900 rounded-2xl border border-slate-200 dark:border-zinc-800 shadow-2xl p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-lg font-semibold text-slate-900 dark:text-zinc-50">
                  {editHabit ? 'Edit Habit' : 'New Habit'}
                </h2>
                <button
                  onClick={onClose}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-all"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-5">
                {/* Title */}
                <div>
                  <label htmlFor="habit-title" className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">
                    Habit Name
                  </label>
                  <input
                    id="habit-title"
                    type="text"
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="e.g., Morning Meditation"
                    autoFocus
                    className="w-full px-4 py-2.5 bg-slate-50 dark:bg-zinc-800/50 border border-slate-200 dark:border-zinc-700 rounded-xl text-sm text-slate-900 dark:text-zinc-50 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all"
                  />
                </div>

                {/* Frequency */}
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-zinc-300 mb-1.5">
                    Frequency
                  </label>
                  <div className="flex gap-2">
                    {['daily', 'weekly'].map((freq) => (
                      <button
                        key={freq}
                        type="button"
                        onClick={() => setFrequency(freq)}
                        className={`flex-1 py-2 rounded-xl text-sm font-medium transition-all ${
                          frequency === freq
                            ? 'bg-indigo-500 text-white shadow-lg shadow-indigo-500/25'
                            : 'bg-slate-100 dark:bg-zinc-800 text-slate-600 dark:text-zinc-400 hover:bg-slate-200 dark:hover:bg-zinc-700'
                        }`}
                      >
                        {freq.charAt(0).toUpperCase() + freq.slice(1)}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Color */}
                <div>
                  <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 dark:text-zinc-300 mb-2">
                    <Palette className="w-4 h-4" />
                    Color
                  </label>
                  <div className="flex gap-2 flex-wrap">
                    {COLORS.map((color) => (
                      <button
                        key={color}
                        type="button"
                        onClick={() => setColorHint(color)}
                        className={`w-8 h-8 rounded-full transition-all ${
                          colorHint === color
                            ? 'ring-2 ring-offset-2 ring-offset-white dark:ring-offset-zinc-900 scale-110'
                            : 'hover:scale-105'
                        }`}
                        style={{
                          backgroundColor: color,
                          ringColor: color,
                        }}
                      />
                    ))}
                  </div>
                </div>

                {/* Submit */}
                <motion.button
                  whileTap={{ scale: 0.98 }}
                  type="submit"
                  disabled={loading || !title.trim()}
                  className="w-full py-2.5 bg-gradient-to-r from-indigo-500 to-indigo-600 hover:from-indigo-600 hover:to-indigo-700 text-white font-medium rounded-xl text-sm shadow-lg shadow-indigo-500/25 transition-all disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {loading ? 'Saving...' : editHabit ? 'Update Habit' : 'Create Habit'}
                </motion.button>
              </form>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
