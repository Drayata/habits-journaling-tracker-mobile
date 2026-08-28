import { useCallback, useEffect, useRef, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'
import { format } from 'date-fns'

export function useJournal(activeDate) {
  const { user } = useAuth()
  const [journal, setJournal] = useState(null)
  const [content, setContent] = useState('')
  const [mood, setMoodState] = useState(null)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const saveTimerRef = useRef(null)

  const dateStr = format(activeDate, 'yyyy-MM-dd')

  // Fetch journal entry for active date
  const fetchJournal = useCallback(async () => {
    if (!user) return
    setLoading(true)
    setSaved(false)

    const { data, error } = await supabase
      .from('journals')
      .select('*')
      .eq('user_id', user.id)
      .eq('entry_date', dateStr)
      .maybeSingle()

    if (!error) {
      setJournal(data)
      setContent(data?.content || '')
      setMoodState(data?.mood || null)
    }
    setLoading(false)
  }, [user, dateStr])

  useEffect(() => {
    fetchJournal()
    // Clear any pending save when date changes
    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current)
    }
  }, [fetchJournal])

  // Debounced save (upsert)
  async function saveEntry(newContent, newMood) {
    if (!user) return
    setSaving(true)
    setSaved(false)

    const payload = {
      user_id: user.id,
      entry_date: dateStr,
      content: newContent ?? content,
      mood: newMood ?? mood,
      updated_at: new Date().toISOString(),
    }

    // Upsert: insert if not exists, update if exists
    const { data, error } = await supabase
      .from('journals')
      .upsert(payload, { onConflict: 'user_id,entry_date' })
      .select()
      .single()

    setSaving(false)
    if (!error && data) {
      setJournal(data)
      setSaved(true)
      // Clear saved indicator after 2s
      setTimeout(() => setSaved(false), 2000)
    }
    return { data, error }
  }

  // Update content with debounced auto-save
  function updateContent(newContent) {
    setContent(newContent)
    setSaved(false)

    if (saveTimerRef.current) {
      clearTimeout(saveTimerRef.current)
    }

    saveTimerRef.current = setTimeout(() => {
      saveEntry(newContent, mood)
    }, 1500)
  }

  // Update mood (saves immediately)
  async function setMood(newMood) {
    setMoodState(newMood)
    await saveEntry(content, newMood)
  }

  // Cleanup
  useEffect(() => {
    return () => {
      if (saveTimerRef.current) {
        clearTimeout(saveTimerRef.current)
      }
    }
  }, [])

  return {
    journal,
    content,
    mood,
    loading,
    saving,
    saved,
    updateContent,
    setMood,
    saveEntry,
  }
}
