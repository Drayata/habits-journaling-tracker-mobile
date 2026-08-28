import {
  format,
  startOfMonth,
  getDay,
  addDays,
  isToday,
  isFuture,
  isSameMonth,
} from 'date-fns'
import { motion } from 'framer-motion'
import { useDate } from '../../contexts/DateContext'
import { isHabitActiveOnDate } from '../../utils/habitUtils'

export default function HeatmapGrid({ completions, habits }) {
  const { monthStart, daysInMonth } = useDate()

  // Get the weekday of the 1st (0 = Sun, 1 = Mon, ... 6 = Sat)
  // We want Monday as the first column, so adjust
  const firstDayRaw = getDay(monthStart) // 0=Sun..6=Sat
  const startOffset = firstDayRaw === 0 ? 6 : firstDayRaw - 1 // Mon=0..Sun=6

  // Build the full grid: padding cells + real day cells
  const cells = []

  // Leading padding cells (days from previous month)
  for (let i = 0; i < startOffset; i++) {
    cells.push({ type: 'pad', key: `pad-start-${i}` })
  }

  // Actual days in the month
  for (let d = 0; d < daysInMonth; d++) {
    const date = addDays(monthStart, d)
    const dateStr = format(date, 'yyyy-MM-dd')
    const count = completions.filter(
      (c) => c.completed_date === dateStr
    ).length
    const activeHabitCount = habits.filter(h => isHabitActiveOnDate(h, date)).length
    
    cells.push({
      type: 'day',
      key: dateStr,
      date,
      dateStr,
      count,
      activeHabitCount,
      isToday: isToday(date),
      isFuture: isFuture(date),
    })
  }

  // Trailing padding cells to complete the last row
  const remainder = cells.length % 7
  if (remainder > 0) {
    for (let i = 0; i < 7 - remainder; i++) {
      cells.push({ type: 'pad', key: `pad-end-${i}` })
    }
  }

  // Split into rows of 7
  const rows = []
  for (let i = 0; i < cells.length; i += 7) {
    rows.push(cells.slice(i, i + 7))
  }

  function getIntensity(count, activeHabitCount) {
    if (count === 0) return 'bg-slate-100 dark:bg-zinc-800/50'
    if (activeHabitCount === 0) return 'bg-emerald-200 dark:bg-emerald-900'
    const ratio = count / activeHabitCount
    if (ratio <= 0.25) return 'bg-emerald-200 dark:bg-emerald-900/60'
    if (ratio <= 0.5) return 'bg-emerald-300 dark:bg-emerald-700'
    if (ratio <= 0.75) return 'bg-emerald-400 dark:bg-emerald-600'
    return 'bg-emerald-500'
  }

  const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S']

  return (
    <div className="space-y-1.5">
      {/* Day labels */}
      <div className="grid grid-cols-7 gap-1.5">
        {dayLabels.map((label, i) => (
          <div
            key={i}
            className="h-5 flex items-center justify-center text-[10px] text-zinc-500 dark:text-zinc-500 font-medium"
          >
            {label}
          </div>
        ))}
      </div>

      {/* Calendar Grid */}
      {rows.map((row, ri) => (
        <div key={ri} className="grid grid-cols-7 gap-1.5">
          {row.map((cell, ci) => {
            if (cell.type === 'pad') {
              return (
                <div
                  key={cell.key}
                  className="aspect-square rounded-lg bg-zinc-50/50 dark:bg-zinc-900/30"
                />
              )
            }

            const globalIdx = ri * 7 + ci

            return (
              <motion.div
                key={cell.key}
                initial={{ scale: 0, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{
                  delay: globalIdx * 0.012,
                  type: 'spring',
                  stiffness: 300,
                  damping: 20,
                }}
                title={`${format(cell.date, 'MMM d')}: ${cell.count} habit${cell.count !== 1 ? 's' : ''}`}
                className={`aspect-square rounded-lg transition-colors relative flex items-center justify-center ${
                  cell.isFuture
                    ? 'bg-zinc-50 dark:bg-zinc-900 border border-dashed border-zinc-200/80 dark:border-zinc-800'
                    : getIntensity(cell.count, cell.activeHabitCount)
                } ${cell.isToday ? 'ring-2 ring-indigo-500 ring-offset-1 ring-offset-white dark:ring-offset-zinc-950' : ''}`}
              >
                <span
                  className={`text-[10px] font-medium leading-none ${
                    cell.isFuture
                      ? 'text-zinc-400 dark:text-zinc-600'
                      : cell.count > 0 && cell.activeHabitCount > 0 && (cell.count / cell.activeHabitCount) > 0.5
                      ? 'text-white/80'
                      : 'text-zinc-500 dark:text-zinc-400'
                  }`}
                >
                  {format(cell.date, 'd')}
                </span>
              </motion.div>
            )
          })}
        </div>
      ))}

      {/* Legend */}
      <div className="flex items-center justify-end gap-1.5 pt-1">
        <span className="text-[10px] text-zinc-500 dark:text-zinc-500 mr-1">Less</span>
        <div className="w-3 h-3 rounded-sm bg-slate-100 dark:bg-zinc-800/50" />
        <div className="w-3 h-3 rounded-sm bg-emerald-200 dark:bg-emerald-900/60" />
        <div className="w-3 h-3 rounded-sm bg-emerald-300 dark:bg-emerald-700" />
        <div className="w-3 h-3 rounded-sm bg-emerald-400 dark:bg-emerald-600" />
        <div className="w-3 h-3 rounded-sm bg-emerald-500" />
        <span className="text-[10px] text-zinc-500 dark:text-zinc-500 ml-1">More</span>
      </div>
    </div>
  )
}
