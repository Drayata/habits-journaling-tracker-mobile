import { BookOpen } from 'lucide-react'

const MOOD_EMOJIS = ['😢', '😕', '😐', '🙂', '😄']

export default function JournalWidget({ journal, isCurrentMonth = true }) {
  const hasMood = journal?.mood != null
  const hasContent = journal?.content && journal.content.trim().length > 0

  return (
    <div className="space-y-3">
      {/* Mood display */}
      {hasMood ? (
        <div className="flex items-center gap-2">
          <span className="text-3xl">{MOOD_EMOJIS[journal.mood - 1]}</span>
          <div>
            <p className="text-sm font-medium text-zinc-900 dark:text-zinc-300">
              {isCurrentMonth ? "Today\u0027s Mood" : 'Logged Mood'}
            </p>
            <p className="text-xs text-zinc-500">
              {['Awful', 'Bad', 'Okay', 'Good', 'Great'][journal.mood - 1]}
            </p>
          </div>
        </div>
      ) : (
        <div className="flex items-center gap-2 text-zinc-500 dark:text-zinc-500">
          <span className="text-2xl opacity-50">😐</span>
          <p className="text-sm">
            {isCurrentMonth
              ? 'No mood logged today'
              : 'No mood logged this month'}
          </p>
        </div>
      )}

      {/* Content preview */}
      {hasContent ? (
        <p className="text-sm text-zinc-500 dark:text-zinc-400 line-clamp-3 leading-relaxed">
          {journal.content}
        </p>
      ) : (
        <div className="flex items-center gap-2 text-zinc-500 dark:text-zinc-500 py-2">
          <BookOpen className="w-4 h-4" />
          <p className="text-sm">
            {isCurrentMonth
              ? 'No journal entry yet today'
              : 'No journal entry for this date'}
          </p>
        </div>
      )}
    </div>
  )
}
