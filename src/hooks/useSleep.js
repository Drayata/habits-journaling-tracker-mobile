import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'
import { useDate } from '../contexts/DateContext'
import { format } from 'date-fns'

export function useSleep() {
  const { user } = useAuth()
  const { monthStartStr, monthEndStr } = useDate()
  const [sleepLogs, setSleepLogs] = useState([])
  const [loading, setLoading] = useState(true)

  // Fetch sleep logs scoped to the selected month
  const fetchSleepLogs = useCallback(async () => {
    if (!user) return
    const { data, error } = await supabase
      .from('sleep_logs')
      .select('*')
      .eq('user_id', user.id)
      .gte('entry_date', monthStartStr)
      .lte('entry_date', monthEndStr)
    
    if (!error && data) {
      setSleepLogs(data)
    }
  }, [user, monthStartStr, monthEndStr])

  useEffect(() => {
    if (user) {
      setLoading(true)
      fetchSleepLogs().finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [user, fetchSleepLogs])

  // Upsert a sleep log for a given date
  async function upsertSleepLog({ date, sleepTime, wakeTime, durationMinutes }) {
    if (!user) return { error: 'User not authenticated' }
    
    const dateStr = format(date, 'yyyy-MM-dd')
    const existing = sleepLogs.find(log => log.entry_date === dateStr)

    const payload = {
      user_id: user.id,
      entry_date: dateStr,
      sleep_time: sleepTime,
      wake_time: wakeTime,
      duration_minutes: durationMinutes,
      updated_at: new Date().toISOString()
    }

    let response;
    
    if (existing) {
      // Update
      response = await supabase
        .from('sleep_logs')
        .update(payload)
        .eq('id', existing.id)
        .select()
        .single()
    } else {
      // Insert
      response = await supabase
        .from('sleep_logs')
        .insert(payload)
        .select()
        .single()
    }

    const { data, error } = response
    
    if (!error && data) {
      setSleepLogs(prev => {
        if (existing) {
          return prev.map(log => log.id === data.id ? data : log)
        }
        return [...prev, data]
      })
    }
    
    return { data, error }
  }

  // Get sleep log for a specific date
  function getSleepLog(date) {
    const dateStr = format(date, 'yyyy-MM-dd')
    return sleepLogs.find(log => log.entry_date === dateStr)
  }

  return {
    sleepLogs,
    loading,
    upsertSleepLog,
    getSleepLog,
    refetch: fetchSleepLogs
  }
}
