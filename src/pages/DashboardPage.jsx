import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { format } from 'date-fns'
import {
  Flame,
  TrendingUp,
  Calendar,
  BookOpen,
  ChevronRight,
  Sparkles,
  BarChart3,
  Info,
  Moon,
  Clock,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { useDate } from '../contexts/DateContext'
import { useHabits } from '../hooks/useHabits'
import { useJournal } from '../hooks/useJournal'
import ProgressRing from '../components/dashboard/ProgressRing'
import HeatmapGrid from '../components/dashboard/HeatmapGrid'
import JournalWidget from '../components/dashboard/JournalWidget'
import MonthNavigator from '../components/dashboard/MonthNavigator'
import SleepInputModal from '../components/habits/SleepInputModal'
import { useSleep } from '../hooks/useSleep'

const cardVariants = {
  hidden: { opacity: 0, y: 16 },
  visible: (i) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.08, duration: 0.4, ease: 'easeOut' },
  }),
}

export default function DashboardPage() {
  const { profile } = useAuth()
  const { activeDate, isCurrentMonth, monthLabel } = useDate()
  const {
    habits,
    completions,
    loading,
    isCompleted,
    toggleCompletion,
    getCompletionRate,
    getBestStreak,
    getActiveHabits,
    getMonthlyCompletionCount,
  } = useHabits()
  const { journal } = useJournal(activeDate)
  const { getSleepLog, upsertSleepLog, loading: sleepLoading } = useSleep()

  const [isSleepModalOpen, setIsSleepModalOpen] = useState(false)

  const todaySleepLog = getSleepLog(activeDate)

  const handleSleepSave = async ({ bedtime, wakeTime, duration }) => {
    await upsertSleepLog({ date: activeDate, sleepTime: bedtime, wakeTime, durationMinutes: duration })
    setIsSleepModalOpen(false)
  }

  const firstName = profile?.full_name?.split(' ')[0] || 'there'
  const hour = new Date().getHours()
  const greeting =
    hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  const todayRate = getCompletionRate(activeDate)
  const bestStreak = getBestStreak()
  const monthlyCompletions = getMonthlyCompletionCount()
  
  const activeHabits = getActiveHabits(activeDate)
  const completedToday = activeHabits.filter((h) =>
    isCompleted(h.id, activeDate)
  ).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-start justify-between"
      >
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-zinc-900 dark:text-white">
            {greeting}, {firstName} ✨
          </h1>
          <p className="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
            {format(new Date(), 'EEEE, MMMM d, yyyy')}
          </p>
        </div>
        <Link
          to="/stats"
          className="flex items-center gap-1.5 px-3 py-2 bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 rounded-xl text-sm font-medium text-zinc-500 dark:text-zinc-400 hover:text-indigo-500 dark:hover:text-indigo-400 hover:border-indigo-300 dark:hover:border-indigo-800 transition-all"
        >
          <BarChart3 className="w-4 h-4" />
          <span className="hidden sm:inline">Statistics</span>
        </Link>
      </motion.div>

      {/* Month Navigator */}
      <MonthNavigator />

      {/* Historical month banner */}
      <AnimatePresence>
        {!isCurrentMonth && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="flex items-center gap-2 px-4 py-2.5 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 rounded-xl text-sm text-amber-700 dark:text-amber-400"
          >
            <Info className="w-4 h-4 flex-shrink-0" />
            <span>
              Viewing <span className="font-semibold">{monthLabel}</span> — switch to the current month to check in.
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bento Grid */}
      <AnimatePresence mode="wait">
        <motion.div
          key={monthLabel}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          {/* ===== Daily Progress Ring ===== */}
          <motion.div
            custom={0}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card flex flex-col items-center justify-center py-6 md:row-span-2"
          >
            <ProgressRing progress={todayRate} size={140} strokeWidth={10} />
            <p className="text-sm font-medium text-zinc-900 dark:text-zinc-50 mt-4">
              {completedToday} of {activeHabits.length} habits
            </p>
            <p className="text-xs text-zinc-500 dark:text-zinc-400 mt-0.5">
              {isCurrentMonth ? 'completed today' : format(activeDate, 'MMM d')}
            </p>
          </motion.div>

          {/* ===== Streak Card ===== */}
          <motion.div
            custom={1}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="w-10 h-10 bg-amber-50 dark:bg-amber-950/30 rounded-xl flex items-center justify-center">
                <Flame className="w-5 h-5 text-amber-500" />
              </div>
              <span className="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                Best Streak
              </span>
            </div>
            <p className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
              {bestStreak}
              <span className="text-lg text-zinc-500 dark:text-zinc-400 font-normal ml-1">days</span>
            </p>
            <p className="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
              {isCurrentMonth
                ? bestStreak > 0 ? 'Keep the momentum going! 🔥' : 'Start your first streak today!'
                : `Best streak within ${monthLabel}`
              }
            </p>
          </motion.div>

          {/* ===== Quick Stats ===== */}
          <motion.div
            custom={2}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="w-10 h-10 bg-indigo-50 dark:bg-indigo-950/30 rounded-xl flex items-center justify-center">
                <TrendingUp className="w-5 h-5 text-indigo-500" />
              </div>
              <span className="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                Overview
              </span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <p className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
                  {getActiveHabits(new Date()).length}
                </p>
                <p className="text-xs text-zinc-500 dark:text-zinc-400">Active Habits</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
                  {monthlyCompletions}
                </p>
                <p className="text-xs text-zinc-500 dark:text-zinc-400">Monthly Completions</p>
              </div>
            </div>
          </motion.div>

          {/* ===== Heatmap ===== */}
          <motion.div
            custom={3}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card md:col-span-2"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4 text-emerald-500" />
                <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-300">
                  {monthLabel}
                </h3>
              </div>
              <Link
                to="/habits"
                className="flex items-center gap-1 text-xs text-indigo-500 hover:text-indigo-400 font-medium transition-colors"
              >
                View All <ChevronRight className="w-3 h-3" />
              </Link>
            </div>
            {loading ? (
              <div className="h-[180px] flex items-center justify-center">
                <div className="w-6 h-6 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
              </div>
            ) : (
              <HeatmapGrid completions={completions} habits={habits} />
            )}
          </motion.div>

          {/* ===== Today's Habits Quick List ===== */}
          <motion.div
            custom={4}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card lg:col-span-2"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-indigo-500" />
                <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-300">
                  {isCurrentMonth ? "Today's Habits" : 'Habits'}
                </h3>
              </div>
              <Link
                to="/habits"
                className="flex items-center gap-1 text-xs text-indigo-500 hover:text-indigo-400 font-medium transition-colors"
              >
                Manage <ChevronRight className="w-3 h-3" />
              </Link>
            </div>

            {activeHabits.length === 0 ? (
              <p className="text-sm text-zinc-500 dark:text-zinc-400 py-4 text-center">
                No habits yet. <Link to="/habits" className="text-indigo-500 hover:underline">Create one!</Link>
              </p>
            ) : (
              <div className="space-y-2 max-h-[200px] overflow-y-auto hide-scrollbar">
                {activeHabits.map((habit) => {
                  const done = isCompleted(habit.id, activeDate)
                  return (
                    <motion.button
                      key={habit.id}
                      whileTap={isCurrentMonth ? { scale: 0.98 } : undefined}
                      onClick={() => {
                        if (isCurrentMonth) {
                          toggleCompletion(habit.id, activeDate)
                        }
                      }}
                      disabled={!isCurrentMonth}
                      className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all ${
                        !isCurrentMonth ? 'opacity-60 cursor-not-allowed' : ''
                      } ${
                        done
                          ? 'bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-100 dark:border-emerald-900/50'
                          : 'bg-zinc-50 dark:bg-zinc-800 border border-zinc-200/80 dark:border-zinc-700 hover:border-zinc-300 dark:hover:border-zinc-600'
                      }`}
                    >
                      <div
                        className={`w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all ${
                          done
                            ? 'border-emerald-500 bg-emerald-500'
                            : 'border-zinc-300 dark:border-zinc-600'
                        }`}
                      >
                        {done && (
                          <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                          </svg>
                        )}
                      </div>
                      <span
                        className={`text-sm font-medium ${
                          done
                            ? 'text-emerald-900 dark:text-emerald-400'
                            : 'text-zinc-700 dark:text-zinc-300'
                        }`}
                      >
                        {habit.title}
                      </span>
                      <div
                        className="w-2 h-2 rounded-full ml-auto"
                        style={{ backgroundColor: habit.color_hint }}
                      />
                    </motion.button>
                  )
                })}
              </div>
            )}
          </motion.div>

          {/* ===== Sleep Log Bento Card ===== */}
          <motion.div
            custom={5}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="relative overflow-hidden rounded-2xl border border-indigo-200/60 dark:border-indigo-900/50 bg-gradient-to-br from-indigo-50 via-violet-50 to-indigo-100 dark:from-indigo-950/40 dark:via-violet-950/30 dark:to-indigo-950/50 p-5 cursor-pointer group transition-all hover:shadow-lg hover:shadow-indigo-500/10 dark:hover:shadow-indigo-500/5"
            onClick={() => setIsSleepModalOpen(true)}
          >
            {/* Decorative glow */}
            <div className="absolute -top-10 -right-10 w-32 h-32 bg-indigo-400/10 dark:bg-indigo-400/5 rounded-full blur-2xl group-hover:bg-indigo-400/20 transition-all duration-500" />
            <div className="absolute -bottom-8 -left-8 w-24 h-24 bg-violet-400/10 dark:bg-violet-400/5 rounded-full blur-2xl" />

            <div className="relative">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shadow-lg shadow-indigo-500/25">
                  <Moon className="w-5 h-5 text-white" />
                </div>
                <h3 className="text-sm font-semibold text-indigo-900 dark:text-indigo-200">
                  Sleep Log
                </h3>
              </div>

              {todaySleepLog ? (
                <div className="space-y-2">
                  <p className="text-2xl font-bold text-indigo-800 dark:text-indigo-100">
                    {Math.floor(todaySleepLog.duration_minutes / 60)}h {todaySleepLog.duration_minutes % 60}m
                  </p>
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5 text-indigo-500/70 dark:text-indigo-400/70" />
                    <span className="text-xs text-indigo-600/70 dark:text-indigo-400/60">
                      {todaySleepLog.sleep_time} → {todaySleepLog.wake_time}
                    </span>
                  </div>
                </div>
              ) : (
                <div className="flex items-center gap-2 py-2">
                  <div className="w-8 h-8 rounded-lg bg-white/60 dark:bg-white/10 flex items-center justify-center group-hover:bg-white/90 dark:group-hover:bg-white/20 transition-all">
                    <Moon className="w-4 h-4 text-indigo-500 dark:text-indigo-300" />
                  </div>
                  <p className="text-sm text-indigo-600/60 dark:text-indigo-400/50">
                    Tap to log sleep
                  </p>
                </div>
              )}
            </div>
          </motion.div>

          {/* ===== Journal Widget ===== */}
          <motion.div
            custom={6}
            variants={cardVariants}
            initial="hidden"
            animate="visible"
            className="bento-card"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-indigo-500" />
                <h3 className="text-sm font-semibold text-zinc-900 dark:text-zinc-300">
                  Journal
                </h3>
              </div>
              <Link
                to="/journal"
                className="flex items-center gap-1 text-xs text-indigo-500 hover:text-indigo-400 font-medium transition-colors"
              >
                Write <ChevronRight className="w-3 h-3" />
              </Link>
            </div>
            <JournalWidget journal={journal} isCurrentMonth={isCurrentMonth} />
          </motion.div>
        </motion.div>
      </AnimatePresence>

      <SleepInputModal
        isOpen={isSleepModalOpen}
        onClose={() => setIsSleepModalOpen(false)}
        onSave={handleSleepSave}
        isLoading={sleepLoading}
        initialBedtime={todaySleepLog?.sleep_time || '22:00'}
        initialWakeTime={todaySleepLog?.wake_time || '06:00'}
      />
    </div>
  )
}
