import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Moon, Sun, X, Clock, Check } from "lucide-react";

export default function SleepInputModal({
  isOpen,
  onClose,
  onSave,
  initialBedtime = "22:45",
  initialWakeTime = "05:00",
  isLoading = false,
}) {
  const [bedtime, setBedtime] = useState(initialBedtime);
  const [wakeTime, setWakeTime] = useState(initialWakeTime);
  const [duration, setDuration] = useState({
    hours: 0,
    minutes: 0,
    totalMinutes: 0,
  });

  useEffect(() => {
    // Reset when opened
    if (isOpen) {
      setBedtime(initialBedtime);
      setWakeTime(initialWakeTime);
    }
  }, [isOpen, initialBedtime, initialWakeTime]);

  useEffect(() => {
    // Calculate duration whenever times change
    if (!bedtime || !wakeTime) return;

    const [bedH, bedM] = bedtime.split(":").map(Number);
    const [wakeH, wakeM] = wakeTime.split(":").map(Number);

    let totalBedMinutes = bedH * 60 + bedM;
    let totalWakeMinutes = wakeH * 60 + wakeM;

    // If wake time is less than bedtime, assume it's the next day
    if (totalWakeMinutes < totalBedMinutes) {
      totalWakeMinutes += 24 * 60;
    }

    const diffMinutes = totalWakeMinutes - totalBedMinutes;
    const h = Math.floor(diffMinutes / 60);
    const m = diffMinutes % 60;

    setDuration({ hours: h, minutes: m, totalMinutes: diffMinutes });
  }, [bedtime, wakeTime]);

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-zinc-900/60 backdrop-blur-sm"
        />

        {/* Modal */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 10 }}
          className="relative w-full max-w-md bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 rounded-2xl shadow-2xl overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-zinc-100 dark:border-zinc-800 bg-indigo-50/50 dark:bg-indigo-950/20">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center">
                <Moon className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
              </div>
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">
                Log Sleep
              </h2>
            </div>
            <button
              onClick={onClose}
              className="p-2 rounded-xl text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="p-6 space-y-6">
            <div className="grid grid-cols-2 gap-4">
              {/* Bedtime Input */}
              <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
                  <Moon className="w-4 h-4 text-indigo-500" />
                  Bedtime
                </label>
                <div className="relative">
                  <input
                    type="time"
                    value={bedtime}
                    onChange={(e) => setBedtime(e.target.value)}
                    className="w-full pl-3 pr-3 py-2.5 bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 rounded-xl text-zinc-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none"
                  />
                </div>
              </div>

              {/* Wake Time Input */}
              <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm font-medium text-zinc-700 dark:text-zinc-300">
                  <Sun className="w-4 h-4 text-amber-500" />
                  Wake Time
                </label>
                <div className="relative">
                  <input
                    type="time"
                    value={wakeTime}
                    onChange={(e) => setWakeTime(e.target.value)}
                    className="w-full pl-3 pr-3 py-2.5 bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 rounded-xl text-zinc-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none"
                  />
                </div>
              </div>
            </div>

            {/* Duration Preview */}
            <div className="flex items-center justify-between p-4 bg-indigo-50 dark:bg-indigo-950/30 border border-indigo-100 dark:border-indigo-900/50 rounded-xl">
              <div className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-indigo-500" />
                <div>
                  <p className="text-xs text-indigo-600/70 dark:text-indigo-400/70 font-medium uppercase tracking-wider">
                    Calculated Sleep
                  </p>
                  <p className="text-lg font-semibold text-indigo-700 dark:text-indigo-300">
                    {duration.hours}h {duration.minutes}m
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 py-4 bg-zinc-50 dark:bg-zinc-800/30 border-t border-zinc-100 dark:border-zinc-800 flex justify-end gap-3">
            <button
              onClick={onClose}
              disabled={isLoading}
              className="px-4 py-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={() =>
                onSave({ bedtime, wakeTime, duration: duration.totalMinutes })
              }
              disabled={isLoading || duration.totalMinutes === 0}
              className="flex items-center gap-2 px-5 py-2 bg-indigo-500 hover:bg-indigo-600 text-white text-sm font-medium rounded-xl transition-all shadow-sm shadow-indigo-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <Check className="w-4 h-4" />
              )}
              Save Log
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
