import { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronLeft, ChevronRight, CalendarDays } from 'lucide-react'
import { useDate } from '../../contexts/DateContext'

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

const SHORT_MONTHS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
]

export default function MonthNavigator() {
  const {
    currentMonth,
    currentYear,
    monthLabel,
    isCurrentMonth,
    goToPrevMonth,
    goToNextMonth,
    goToMonth,
    goToCurrentMonth,
  } = useDate()

  const [showPicker, setShowPicker] = useState(false)
  const [pickerYear, setPickerYear] = useState(currentYear)
  const [slideDir, setSlideDir] = useState(0) // -1 = left, 1 = right
  const pickerRef = useRef(null)

  // Close picker on outside click
  useEffect(() => {
    function handleClickOutside(e) {
      if (pickerRef.current && !pickerRef.current.contains(e.target)) {
        setShowPicker(false)
      }
    }
    if (showPicker) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [showPicker])

  // Sync picker year when month/year changes externally
  useEffect(() => {
    setPickerYear(currentYear)
  }, [currentYear])

  function handlePrev() {
    setSlideDir(-1)
    goToPrevMonth()
  }

  function handleNext() {
    setSlideDir(1)
    goToNextMonth()
  }

  function handlePickMonth(month) {
    goToMonth(month, pickerYear)
    setShowPicker(false)
  }

  const now = new Date()
  const realMonth = now.getMonth()
  const realYear = now.getFullYear()

  return (
    <div className="relative">
      <div className="flex items-center justify-between gap-3">
        {/* Navigation Row */}
        <div className="flex items-center gap-2">
          {/* Prev Button */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={handlePrev}
            className="w-9 h-9 flex items-center justify-center rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 text-zinc-500 dark:text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:border-zinc-300 dark:hover:border-zinc-600 transition-all"
            aria-label="Previous month"
          >
            <ChevronLeft className="w-4 h-4" />
          </motion.button>

          {/* Month/Year Label (clickable for picker) */}
          <motion.button
            whileTap={{ scale: 0.97 }}
            onClick={() => {
              setPickerYear(currentYear)
              setShowPicker((prev) => !prev)
            }}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 hover:border-indigo-300 dark:hover:border-indigo-800 transition-all min-w-[180px] justify-center"
          >
            <CalendarDays className="w-4 h-4 text-indigo-500" />
            <AnimatePresence mode="wait" initial={false}>
              <motion.span
                key={monthLabel}
                initial={{ opacity: 0, y: slideDir * 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: slideDir * -12 }}
                transition={{ duration: 0.2, ease: 'easeOut' }}
                className="text-sm font-semibold text-zinc-900 dark:text-zinc-50"
              >
                {monthLabel}
              </motion.span>
            </AnimatePresence>
          </motion.button>

          {/* Next Button */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={handleNext}
            className="w-9 h-9 flex items-center justify-center rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 text-zinc-500 dark:text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:border-zinc-300 dark:hover:border-zinc-600 transition-all"
            aria-label="Next month"
          >
            <ChevronRight className="w-4 h-4" />
          </motion.button>
        </div>

        {/* Today Pill */}
        <AnimatePresence>
          {!isCurrentMonth && (
            <motion.button
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              whileTap={{ scale: 0.95 }}
              onClick={goToCurrentMonth}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-800 text-xs font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 dark:hover:bg-indigo-950/60 transition-all"
            >
              <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse" />
              Today
            </motion.button>
          )}
        </AnimatePresence>
      </div>

      {/* Month Picker Dropdown */}
      <AnimatePresence>
        {showPicker && (
          <motion.div
            ref={pickerRef}
            initial={{ opacity: 0, y: -8, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.96 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="absolute left-0 top-full mt-2 z-50 w-[280px] bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 rounded-2xl shadow-xl dark:shadow-2xl shadow-zinc-200/50 dark:shadow-black/50 p-4"
          >
            {/* Year navigation */}
            <div className="flex items-center justify-between mb-3">
              <button
                onClick={() => setPickerYear((y) => y - 1)}
                className="w-7 h-7 flex items-center justify-center rounded-lg text-zinc-500 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <span className="text-sm font-semibold text-zinc-900 dark:text-zinc-50">
                {pickerYear}
              </span>
              <button
                onClick={() => setPickerYear((y) => y + 1)}
                className="w-7 h-7 flex items-center justify-center rounded-lg text-zinc-500 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Month grid */}
            <div className="grid grid-cols-3 gap-1.5">
              {SHORT_MONTHS.map((name, i) => {
                const isSelected =
                  i === currentMonth && pickerYear === currentYear
                const isNow = i === realMonth && pickerYear === realYear

                return (
                  <motion.button
                    key={name}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => handlePickMonth(i)}
                    className={`py-2 px-1 rounded-xl text-xs font-medium transition-all ${
                      isSelected
                        ? 'bg-indigo-500 text-white shadow-sm shadow-indigo-500/25'
                        : isNow
                        ? 'bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800'
                        : 'text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800'
                    }`}
                  >
                    {name}
                  </motion.button>
                )
              })}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
