import { createContext, useContext, useMemo, useState } from 'react'
import {
  startOfMonth,
  endOfMonth,
  getDaysInMonth,
  format,
  isSameMonth,
} from 'date-fns'

const DateContext = createContext({})

export function DateProvider({ children }) {
  const [activeDate, setActiveDate] = useState(new Date())

  const now = new Date()
  const [currentMonth, setCurrentMonth] = useState(now.getMonth()) // 0-11
  const [currentYear, setCurrentYear] = useState(now.getFullYear())

  // Derived month boundaries
  const monthDate = useMemo(
    () => new Date(currentYear, currentMonth, 1),
    [currentMonth, currentYear]
  )
  const monthStart = useMemo(() => startOfMonth(monthDate), [monthDate])
  const monthEnd = useMemo(() => endOfMonth(monthDate), [monthDate])
  const daysInMonth = useMemo(() => getDaysInMonth(monthDate), [monthDate])
  const monthLabel = useMemo(
    () => format(monthDate, 'MMMM yyyy'),
    [monthDate]
  )
  const isCurrentMonth = useMemo(
    () => isSameMonth(monthDate, new Date()),
    [monthDate]
  )

  // Month-formatted strings for Supabase queries
  const monthStartStr = useMemo(
    () => format(monthStart, 'yyyy-MM-dd'),
    [monthStart]
  )
  const monthEndStr = useMemo(
    () => format(monthEnd, 'yyyy-MM-dd'),
    [monthEnd]
  )

  function goToPrevMonth() {
    if (currentMonth === 0) {
      setCurrentMonth(11)
      setCurrentYear((y) => y - 1)
    } else {
      setCurrentMonth((m) => m - 1)
    }
  }

  function goToNextMonth() {
    if (currentMonth === 11) {
      setCurrentMonth(0)
      setCurrentYear((y) => y + 1)
    } else {
      setCurrentMonth((m) => m + 1)
    }
  }

  function goToMonth(month, year) {
    setCurrentMonth(month)
    setCurrentYear(year)
  }

  function goToCurrentMonth() {
    const today = new Date()
    setCurrentMonth(today.getMonth())
    setCurrentYear(today.getFullYear())
  }

  return (
    <DateContext.Provider
      value={{
        // Existing daily API (preserved for DateBar, JournalPage, HabitsPage)
        activeDate,
        setActiveDate,
        // New monthly API
        currentMonth,
        currentYear,
        monthStart,
        monthEnd,
        monthStartStr,
        monthEndStr,
        daysInMonth,
        monthLabel,
        isCurrentMonth,
        goToPrevMonth,
        goToNextMonth,
        goToMonth,
        goToCurrentMonth,
      }}
    >
      {children}
    </DateContext.Provider>
  )
}

export function useDate() {
  const context = useContext(DateContext)
  if (!context) {
    throw new Error('useDate must be used within a DateProvider')
  }
  return context
}
