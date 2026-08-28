import { motion, AnimatePresence } from 'framer-motion'
import { Check, Flame, MoreVertical, Pencil, Trash2, GripVertical } from 'lucide-react'
import { useState } from 'react'

export default function HabitCard({
  habit,
  completed,
  streak,
  onToggle,
  onEdit,
  onDelete,
  draggableProps,
  dragHandleProps,
  isDragging,
  innerRef,
}) {
  const [showMenu, setShowMenu] = useState(false)

  return (
    <div
      ref={innerRef}
      {...draggableProps}
      className={`bento-card flex items-center gap-3 group transition-all ${
        isDragging
          ? 'scale-[1.02] shadow-xl border-indigo-300 dark:border-indigo-700 bg-white dark:bg-zinc-900 z-50'
          : ''
      }`}
    >
      {/* Drag handle */}
      <div
        {...dragHandleProps}
        className="cursor-grab active:cursor-grabbing p-1 -ml-2 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300 transition-colors"
      >
        <GripVertical className="w-5 h-5" />
      </div>

      {/* Color accent */}
      <div
        className="w-1 h-10 rounded-full flex-shrink-0"
        style={{ backgroundColor: habit.color_hint || '#10b981' }}
      />

      {/* Toggle button */}
      <motion.button
        whileTap={{ scale: 0.85 }}
        onClick={onToggle}
        className={`w-9 h-9 rounded-xl flex-shrink-0 flex items-center justify-center border-2 transition-all duration-300 ${
          completed
            ? 'border-emerald-500 bg-emerald-500 shadow-lg shadow-emerald-500/25'
            : 'border-zinc-300 dark:border-zinc-600 hover:border-emerald-400 dark:hover:border-emerald-500'
        }`}
      >
        <AnimatePresence mode="wait">
          {completed && (
            <motion.div
              initial={{ scale: 0, rotate: -45 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0, rotate: 45 }}
              transition={{ type: 'spring', stiffness: 500, damping: 25 }}
            >
              <Check className="w-4.5 h-4.5 text-white" strokeWidth={3} />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.button>

      {/* Habit info */}
      <div className="flex-1 min-w-0">
        <h3
          className={`text-sm font-medium transition-all duration-300 ${
            completed
              ? 'text-zinc-500 dark:text-zinc-400 line-through'
              : 'text-zinc-700 dark:text-zinc-300'
          }`}
        >
          {habit.title}
        </h3>
        <div className="flex items-center gap-2 mt-0.5">
          <span className="text-xs text-zinc-500 dark:text-zinc-400 capitalize">
            {habit.frequency}
          </span>
          {streak > 0 && (
            <span className="flex items-center gap-0.5 text-xs font-medium text-amber-500">
              <Flame className="w-3 h-3" />
              {streak}d
            </span>
          )}
        </div>
      </div>

      {/* Actions menu */}
      <div className="relative">
        <button
          onClick={() => setShowMenu(!showMenu)}
          className="p-1.5 rounded-lg text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-700/50 opacity-0 group-hover:opacity-100 transition-all"
        >
          <MoreVertical className="w-4 h-4" />
        </button>

        <AnimatePresence>
          {showMenu && (
            <>
              <div
                className="fixed inset-0 z-40"
                onClick={() => setShowMenu(false)}
              />
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: -4 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: -4 }}
                className="absolute right-0 top-full mt-1 z-50 w-36 bg-white dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 rounded-xl shadow-xl overflow-hidden"
              >
                <button
                  onClick={() => {
                    setShowMenu(false)
                    onEdit()
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-slate-50 dark:hover:bg-zinc-700/50 transition-colors"
                >
                  <Pencil className="w-3.5 h-3.5" />
                  Edit
                </button>
                <button
                  onClick={() => {
                    setShowMenu(false)
                    onDelete()
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20 transition-colors"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  Delete
                </button>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}
