import { startOfDay } from 'date-fns'

/**
 * Determines if a habit was active (created and not archived) on a specific date.
 * 
 * @param {Object} habit - The habit object containing created_at, is_archived, archived_at.
 * @param {Date|string} date - The target date to evaluate against.
 * @returns {boolean} True if the habit existed and was not archived as of the target date.
 */
export function isHabitActiveOnDate(habit, date) {
  if (!habit || !date) return false

  const targetDate = startOfDay(new Date(date))
  const createdDate = startOfDay(new Date(habit.created_at))

  // The habit must have been created on or before the target date
  if (createdDate > targetDate) {
    return false
  }

  // If the habit is not archived, it's active
  if (!habit.is_archived) {
    return true
  }

  // If the habit is archived, it was active only if the target date is strictly BEFORE the archive date
  // (or you can decide inclusive/exclusive. Usually if it was archived today, it counts for today).
  const archivedDate = startOfDay(new Date(habit.archived_at))
  if (targetDate <= archivedDate) {
    return true
  }

  return false
}
