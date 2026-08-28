import { motion } from 'framer-motion'
import { format } from 'date-fns'
import { Save, Check, Loader2, BookOpen } from 'lucide-react'
import { useDate } from '../contexts/DateContext'
import { useJournal } from '../hooks/useJournal'
import DateBar from '../components/habits/DateBar'

const MOODS = [
  { value: 1, emoji: '😢', label: 'Awful' },
  { value: 2, emoji: '😕', label: 'Bad' },
  { value: 3, emoji: '😐', label: 'Okay' },
  { value: 4, emoji: '🙂', label: 'Good' },
  { value: 5, emoji: '😄', label: 'Great' },
]

export default function JournalPage() {
  const { activeDate } = useDate()
  const { content, mood, loading, saving, saved, updateContent, setMood } =
    useJournal(activeDate)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
            Journal
          </h1>
          <p className="text-sm text-zinc-500 dark:text-zinc-400 mt-0.5">
            {format(activeDate, 'EEEE, MMMM d, yyyy')}
          </p>
        </div>
        {/* Save status */}
        <div className="flex items-center gap-1.5">
          {saving && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-1.5 text-sm text-zinc-500"
            >
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
              <span>Saving...</span>
            </motion.div>
          )}
          {saved && !saving && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex items-center gap-1.5 text-sm text-emerald-500"
            >
              <Check className="w-3.5 h-3.5" />
              <span>Saved</span>
            </motion.div>
          )}
        </div>
      </div>

      {/* Date Bar */}
      <DateBar />

      {/* Mood Selector */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bento-card"
      >
        <h3 className="text-sm font-medium text-zinc-900 dark:text-zinc-300 mb-3">
          How are you feeling?
        </h3>
        <div className="flex items-center justify-between gap-2">
          {MOODS.map((m) => (
            <motion.button
              key={m.value}
              whileTap={{ scale: 0.9 }}
              onClick={() => setMood(m.value)}
              className={`flex-1 flex flex-col items-center gap-1 py-3 rounded-xl transition-all ${
                mood === m.value
                  ? 'bg-indigo-50 dark:bg-indigo-950/40 border-2 border-indigo-300 dark:border-indigo-700 shadow-sm'
                  : 'border-2 border-transparent hover:bg-zinc-50 dark:hover:bg-zinc-800/50'
              }`}
            >
              <span className={`text-2xl transition-transform ${mood === m.value ? 'scale-110' : ''}`}>
                {m.emoji}
              </span>
              <span className={`text-[10px] font-medium ${
                mood === m.value
                  ? 'text-indigo-600 dark:text-indigo-400'
                  : 'text-zinc-500 dark:text-zinc-500'
              }`}>
                {m.label}
              </span>
            </motion.button>
          ))}
        </div>
      </motion.div>

      {/* Journal Editor */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bento-card"
      >
        <div className="flex items-center gap-2 mb-3">
          <BookOpen className="w-4 h-4 text-indigo-500" />
          <h3 className="text-sm font-medium text-zinc-900 dark:text-zinc-300">
            Today&apos;s Entry
          </h3>
        </div>

        {loading ? (
          <div className="h-[300px] flex items-center justify-center">
            <div className="w-6 h-6 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <textarea
            id="journal-editor"
            value={content}
            onChange={(e) => updateContent(e.target.value)}
            placeholder="Write about your day, reflect on your progress, or just let your thoughts flow..."
            className="w-full min-h-[300px] md:min-h-[400px] bg-transparent text-zinc-900 dark:text-zinc-200 text-sm leading-relaxed placeholder-zinc-400 dark:placeholder-zinc-600 resize-none focus:outline-none"
          />
        )}
      </motion.div>

      {/* Writing tips */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="text-center py-4"
      >
        <p className="text-xs text-zinc-500 dark:text-zinc-500">
          💡 Your journal auto-saves as you type. Take your time.
        </p>
      </motion.div>
    </div>
  )
}
