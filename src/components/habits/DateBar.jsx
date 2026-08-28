import { useRef, useEffect } from 'react'
import { format, addDays, subDays, isToday, isSameDay } from 'date-fns'
import { motion } from 'framer-motion'
import { useDate } from '../../contexts/DateContext'
import { ChevronLeft, ChevronRight } from 'lucide-react'

export default function DateBar() {
  const { activeDate, setActiveDate } = useDate()
  const scrollRef = useRef(null)

  // Generate 15 days centered around active date
  const days = []
  for (let i = -7; i <= 7; i++) {
    days.push(addDays(activeDate, i))
  }

  // Scroll to center on mount and when active date changes
  useEffect(() => {
    if (scrollRef.current) {
      const container = scrollRef.current
      const activeEl = container.querySelector('[data-active="true"]')
      if (activeEl) {
        activeEl.scrollIntoView({
          behavior: 'smooth',
          block: 'nearest',
          inline: 'center',
        })
      }
    }
  }, [activeDate])

  return (
    <div className="relative">
      {/* Navigation arrows (desktop) */}
      <button
        onClick={() => setActiveDate(subDays(activeDate, 1))}
        className="hidden md:flex absolute left-0 top-1/2 -translate-y-1/2 z-10 w-8 h-8 items-center justify-center rounded-full bg-white dark:bg-zinc-800 border border-zinc-200/80 dark:border-zinc-700 text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300 shadow-sm transition-all"
      >
        <ChevronLeft className="w-4 h-4" />
      </button>
      <button
        onClick={() => setActiveDate(addDays(activeDate, 1))}
        className="hidden md:flex absolute right-0 top-1/2 -translate-y-1/2 z-10 w-8 h-8 items-center justify-center rounded-full bg-white dark:bg-zinc-800 border border-zinc-200/80 dark:border-zinc-700 text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300 shadow-sm transition-all"
      >
        <ChevronRight className="w-4 h-4" />
      </button>

      <div
        ref={scrollRef}
        className="flex gap-2 overflow-x-auto hide-scrollbar px-2 md:px-10 py-2"
      >
        {days.map((day) => {
          const active = isSameDay(day, activeDate)
          const today = isToday(day)

          return (
            <motion.button
              key={day.toISOString()}
              data-active={active}
              whileTap={{ scale: 0.95 }}
              onClick={() => setActiveDate(day)}
              className={`flex-shrink-0 flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl text-xs font-medium transition-all min-w-[52px] ${
                active
                  ? 'bg-indigo-500 text-white shadow-lg shadow-indigo-500/25'
                  : today
                  ? 'bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800'
                  : 'bg-white dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400 border border-zinc-200/80 dark:border-zinc-700 hover:border-zinc-300 dark:hover:border-zinc-600'
              }`}
            >
              <span className={`text-[10px] uppercase tracking-wider ${active ? 'text-indigo-100' : 'text-zinc-500 dark:text-zinc-500'}`}>
                {format(day, 'EEE')}
              </span>
              <span className="text-lg font-semibold leading-none">
                {format(day, 'd')}
              </span>
              <span className={`text-[10px] ${active ? 'text-indigo-200' : 'text-zinc-500 dark:text-zinc-500'}`}>
                {format(day, 'MMM')}
              </span>
            </motion.button>
          )
        })}
      </div>
    </div>
  )
}
