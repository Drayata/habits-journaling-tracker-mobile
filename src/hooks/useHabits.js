import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'
import { useDate } from '../contexts/DateContext'
import {
  format,
  subDays,
  startOfDay,
  eachDayOfInterval,
} from 'date-fns'
import { isHabitActiveOnDate } from '../utils/habitUtils'

export function useHabits() {
  const { user } = useAuth()
  const { monthStartStr, monthEndStr, monthStart, monthEnd } = useDate()
  const [habits, setHabits] = useState([])
  const [completions, setCompletions] = useState([])
  const [loading, setLoading] = useState(true)

  // Fetch all habits for the user
  const fetchHabits = useCallback(async () => {
    if (!user) return
    const { data, error } = await supabase
      .from('habits')
      .select('*')
      .eq('user_id', user.id)
      .order('position', { ascending: true })
      .order('created_at', { ascending: true })
    if (!error && data) setHabits(data)
  }, [user])

  // Fetch completions scoped to the selected month
  const fetchCompletions = useCallback(async () => {
    if (!user) return
    const { data, error } = await supabase
      .from('habit_completions')
      .select('*')
      .eq('user_id', user.id)
      .gte('completed_date', monthStartStr)
      .lte('completed_date', monthEndStr)
    if (!error && data) setCompletions(data)
  }, [user, monthStartStr, monthEndStr])

  useEffect(() => {
    if (user) {
      setLoading(true)
      Promise.all([fetchHabits(), fetchCompletions()]).finally(() =>
        setLoading(false)
      )
    } else {
      setLoading(false)
    }
  }, [user, fetchHabits, fetchCompletions])

  // Check if a habit is completed for a specific date
  function isCompleted(habitId, date) {
    const dateStr = format(date, 'yyyy-MM-dd')
    return completions.some(
      (c) => c.habit_id === habitId && c.completed_date === dateStr
    )
  }

  // Toggle habit completion with optimistic UI
  async function toggleCompletion(habitId, date) {
    if (!user) return
    const dateStr = format(date, 'yyyy-MM-dd')
    const existing = completions.find(
      (c) => c.habit_id === habitId && c.completed_date === dateStr
    )

    if (existing) {
      // Optimistic delete
      setCompletions((prev) => prev.filter((c) => c.id !== existing.id))
      const { error } = await supabase
        .from('habit_completions')
        .delete()
        .eq('id', existing.id)
      if (error) {
        // Rollback on error
        setCompletions((prev) => [...prev, existing])
      }
    } else {
      // Optimistic insert
      const tempId = crypto.randomUUID()
      const optimistic = {
        id: tempId,
        habit_id: habitId,
        user_id: user.id,
        completed_date: dateStr,
      }
      setCompletions((prev) => [...prev, optimistic])

      const { data, error } = await supabase
        .from('habit_completions')
        .insert({
          habit_id: habitId,
          user_id: user.id,
          completed_date: dateStr,
        })
        .select()
        .single()

      if (error) {
        // Rollback
        setCompletions((prev) => prev.filter((c) => c.id !== tempId))
      } else if (data) {
        // Replace temp with real
        setCompletions((prev) =>
          prev.map((c) => (c.id === tempId ? data : c))
        )
      }
    }
  }

  // Calculate streak for a habit (consecutive days ending today)
  function getStreak(habitId) {
    const habit = habits.find(h => h.id === habitId)
    if (!habit) return 0

    const habitCompletions = completions
      .filter((c) => c.habit_id === habitId)
      .map((c) => c.completed_date)
      .sort()
      .reverse()

    if (habitCompletions.length === 0) return 0

    let streak = 0
    let checkDate = startOfDay(new Date())
    let missedCounter = 0

    // Check if today is completed; if not, start from yesterday
    const todayStr = format(checkDate, 'yyyy-MM-dd')
    if (!habitCompletions.includes(todayStr)) {
      missedCounter = 1 // Today acts as our 1 allowed missed day
      checkDate = subDays(checkDate, 1)
    }

    for (let i = 0; i < 365; i++) {
      if (!isHabitActiveOnDate(habit, checkDate)) break
      const dateStr = format(checkDate, 'yyyy-MM-dd')
      
      if (habitCompletions.includes(dateStr)) {
        // Habit was completed: increment streak and reset missedCounter
        streak++
        missedCounter = 0
      } else {
        // Habit was NOT completed
        missedCounter++
        if (missedCounter >= 2) {
          // Two consecutive missed days found, break immediately
          break
        }
        // If missedCounter === 1, do NOT break the loop yet (skip but preserve streak)
      }
      checkDate = subDays(checkDate, 1)
    }

    return streak
  }

  // Get the best streak within the selected month
  function getBestStreak() {
    if (habits.length === 0) return 0

    // Get all days in the month
    const monthDays = eachDayOfInterval({ start: monthStart, end: monthEnd })

    let bestStreak = 0

    for (const habit of habits) {
      const habitDates = new Set(
        completions
          .filter((c) => c.habit_id === habit.id)
          .map((c) => c.completed_date)
      )

      let currentStreak = 0
      let missedCounter = 0
      
      for (const day of monthDays) {
        if (!isHabitActiveOnDate(habit, day)) {
          currentStreak = 0
          missedCounter = 0
          continue
        }

        const dateStr = format(day, 'yyyy-MM-dd')
        if (habitDates.has(dateStr)) {
          currentStreak++
          missedCounter = 0
          bestStreak = Math.max(bestStreak, currentStreak)
        } else {
          missedCounter++
          if (missedCounter >= 2) {
            currentStreak = 0
          }
        }
      }
    }

    return bestStreak
  }

  // Get active habits for a specific date
  function getActiveHabits(date) {
    return habits.filter(habit =>
      isHabitActiveOnDate(habit, date) &&
      habit.title.toLowerCase() !== 'sleep tracker'
    )
  }

  // Get completions count for a specific date
  function getCompletedCount(date) {
    const dateStr = format(date, 'yyyy-MM-dd')
    return completions.filter((c) => c.completed_date === dateStr).length
  }

  // Get completion rate for a date (0-1)
  function getCompletionRate(date) {
    const activeHabits = getActiveHabits(date)
    if (activeHabits.length === 0) return 0
    return getCompletedCount(date) / activeHabits.length
  }

  // Get total completions count for the active month
  function getMonthlyCompletionCount() {
    return completions.length
  }

  // CRUD: Add habit
  async function addHabit({ title, frequency = 'daily', color_hint = '#10b981' }) {
    if (!user) return
    const nextPosition = habits.length > 0 ? Math.max(...habits.map(h => h.position || 0)) + 1 : 0
    
    const { data, error } = await supabase
      .from('habits')
      .insert({
        user_id: user.id,
        title,
        frequency,
        color_hint,
        position: nextPosition,
      })
      .select()
      .single()
    if (!error && data) {
      setHabits((prev) => [...prev, data])
    }
    return { data, error }
  }

  // CRUD: Update habit
  async function updateHabit(habitId, updates) {
    const { data, error } = await supabase
      .from('habits')
      .update(updates)
      .eq('id', habitId)
      .select()
      .single()
    if (!error && data) {
      setHabits((prev) => prev.map((h) => (h.id === habitId ? data : h)))
    }
    return { data, error }
  }

  // CRUD: Delete habit
  async function deleteHabit(habitId) {
    const removed = habits.find((h) => h.id === habitId)
    if (!removed) return

    // Optimistic removal from both habits and completions
    setHabits((prev) => prev.filter((h) => h.id !== habitId))
    setCompletions((prev) => prev.filter((c) => c.habit_id !== habitId))

    const { error } = await supabase
      .from('habits')
      .delete()
      .eq('id', habitId)

    if (error) {
      // Rollback on failure
      setHabits((prev) => [...prev, removed])
    }
  }

  // Reorder habits
  async function reorderHabits(activeHabits, startIndex, endIndex) {
    if (!user || startIndex === endIndex) return
    
    const result = Array.from(activeHabits)
    const [removed] = result.splice(startIndex, 1)
    result.splice(endIndex, 0, removed)
    
    // Gather current positions of the active habits, sorted
    const currentPositions = activeHabits.map(h => h.position || 0).sort((a, b) => a - b)
    
    // Assign these positions to the newly ordered items
    const updatedActiveHabits = result.map((habit, index) => ({
      ...habit,
      position: currentPositions[index],
    }))
    
    // Optimistic UI update
    setHabits(prev => {
      const newHabits = prev.map(h => {
        const updated = updatedActiveHabits.find(uh => uh.id === h.id)
        return updated ? updated : h
      })
      return newHabits.sort((a, b) => (a.position || 0) - (b.position || 0))
    })

    // Batch update to Supabase
    const updates = updatedActiveHabits.map((h) => ({
      id: h.id,
      user_id: user.id,
      title: h.title,
      frequency: h.frequency,
      color_hint: h.color_hint,
      created_at: h.created_at,
      is_archived: h.is_archived,
      archived_at: h.archived_at,
      position: h.position,
    }))

    const { error } = await supabase
      .from('habits')
      .upsert(updates, { onConflict: 'id' })

    if (error) {
      console.error('Error reordering habits:', error)
    }
  }

  return {
    habits,
    completions,
    loading,
    isCompleted,
    toggleCompletion,
    getStreak,
    getBestStreak,
    getActiveHabits,
    getCompletedCount,
    getCompletionRate,
    getMonthlyCompletionCount,
    addHabit,
    updateHabit,
    deleteHabit,
    reorderHabits,
    refetch: () => Promise.all([fetchHabits(), fetchCompletions()]),
  }
}
