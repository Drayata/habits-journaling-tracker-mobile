import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { DragDropContext, Droppable, Draggable } from "@hello-pangea/dnd";
import { Plus, Target, Moon, Clock } from "lucide-react";
import { useDate } from "../contexts/DateContext";
import { useHabits } from "../hooks/useHabits";
import DateBar from "../components/habits/DateBar";
import HabitCard from "../components/habits/HabitCard";
import HabitFormModal from "../components/habits/HabitFormModal";
import SleepInputModal from "../components/habits/SleepInputModal";
import { useSleep } from "../hooks/useSleep";
import { format } from "date-fns";

export default function HabitsPage() {
  const { activeDate } = useDate();
  const {
    loading,
    isCompleted,
    toggleCompletion,
    getStreak,
    addHabit,
    updateHabit,
    deleteHabit,
    getActiveHabits,
    reorderHabits,
  } = useHabits();

  const [showModal, setShowModal] = useState(false);
  const [editingHabit, setEditingHabit] = useState(null);

  const [isSleepModalOpen, setIsSleepModalOpen] = useState(false);

  const { getSleepLog, upsertSleepLog, loading: sleepLoading } = useSleep();
  const todaySleepLog = getSleepLog(activeDate);

  const activeHabits = getActiveHabits(activeDate);
  const completedCount = activeHabits.filter((h) =>
    isCompleted(h.id, activeDate),
  ).length;

  async function handleSubmit(values) {
    if (editingHabit) {
      await updateHabit(editingHabit.id, values);
    } else {
      await addHabit(values);
    }
  }

  function handleEdit(habit) {
    setEditingHabit(habit);
    setShowModal(true);
  }

  function handleClose() {
    setShowModal(false);
    setEditingHabit(null);
  }

  const handleSleepSave = async ({ bedtime, wakeTime, duration }) => {
    await upsertSleepLog({
      date: activeDate,
      sleepTime: bedtime,
      wakeTime,
      durationMinutes: duration,
    });
    setIsSleepModalOpen(false);
  };

  const handleDragEnd = (result) => {
    if (!result.destination) return;
    if (result.destination.index === result.source.index) return;

    reorderHabits(activeHabits, result.source.index, result.destination.index);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">
            Habits
          </h1>
          <p className="text-sm text-zinc-500 dark:text-zinc-400 mt-0.5">
            {format(activeDate, "EEEE, MMMM d")} · {completedCount}/
            {activeHabits.length} done
          </p>
        </div>
        <motion.button
          whileTap={{ scale: 0.95 }}
          onClick={() => {
            setEditingHabit(null);
            setShowModal(true);
          }}
          className="flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-indigo-500 to-indigo-600 text-white text-sm font-medium rounded-xl shadow-lg shadow-indigo-500/25 hover:shadow-xl hover:shadow-indigo-500/30 transition-all"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">Add Habit</span>
        </motion.button>
      </div>

      {/* Date Bar */}
      <DateBar />

      {/* Habits List */}
      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bento-card h-[72px] animate-pulse-soft" />
          ))}
        </div>
      ) : activeHabits.length === 0 ? (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="bento-card flex flex-col items-center justify-center py-12 text-center"
        >
          <div className="w-16 h-16 bg-indigo-50 dark:bg-indigo-950/30 rounded-2xl flex items-center justify-center mb-4">
            <Target className="w-8 h-8 text-indigo-400" />
          </div>
          <h3 className="text-base font-semibold text-zinc-900 dark:text-zinc-300 mb-1">
            No habits yet
          </h3>
          <p className="text-sm text-zinc-500 dark:text-zinc-500 max-w-xs">
            Start building better routines by adding your first habit.
          </p>
        </motion.div>
      ) : (
        <DragDropContext onDragEnd={handleDragEnd}>
          <Droppable droppableId="habits-list">
            {(provided) => (
              <div
                {...provided.droppableProps}
                ref={provided.innerRef}
                className="space-y-2"
              >
                {activeHabits.map((habit, index) => (
                  <Draggable
                    key={habit.id}
                    draggableId={habit.id}
                    index={index}
                  >
                    {(provided, snapshot) => (
                      <HabitCard
                        habit={habit}
                        completed={isCompleted(habit.id, activeDate)}
                        streak={getStreak(habit.id)}
                        onToggle={() => toggleCompletion(habit.id, activeDate)}
                        onEdit={() => handleEdit(habit)}
                        onDelete={() => deleteHabit(habit.id)}
                        innerRef={provided.innerRef}
                        draggableProps={provided.draggableProps}
                        dragHandleProps={provided.dragHandleProps}
                        isDragging={snapshot.isDragging}
                      />
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        </DragDropContext>
      )}

      {/* Progress summary */}
      {activeHabits.length > 0 && (
        <div className="bento-card">
          <div className="flex items-center justify-between mb-3">
            <span className="text-sm font-medium text-zinc-900 dark:text-zinc-300">
              Today&apos;s Progress
            </span>
            <span className="text-sm font-semibold text-emerald-500">
              {activeHabits.length > 0
                ? Math.round((completedCount / activeHabits.length) * 100)
                : 0}
              %
            </span>
          </div>
          <div className="h-2 bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{
                width: `${activeHabits.length > 0 ? (completedCount / activeHabits.length) * 100 : 0}%`,
              }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              className="h-full bg-gradient-to-r from-emerald-400 to-emerald-500 rounded-full"
            />
          </div>
        </div>
      )}

      {/* ===== Standalone Sleep Tracker Widget ===== */}
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.15, duration: 0.4, ease: "easeOut" }}
        className="relative overflow-hidden rounded-2xl border border-indigo-200/60 dark:border-indigo-900/50 bg-gradient-to-br from-indigo-50 via-violet-50 to-indigo-100 dark:from-indigo-950/40 dark:via-violet-950/30 dark:to-indigo-950/50 p-5 cursor-pointer group transition-all hover:shadow-lg hover:shadow-indigo-500/10 dark:hover:shadow-indigo-500/5"
        onClick={() => setIsSleepModalOpen(true)}
      >
        {/* Decorative glow */}
        <div className="absolute -top-10 -right-10 w-32 h-32 bg-indigo-400/10 dark:bg-indigo-400/5 rounded-full blur-2xl group-hover:bg-indigo-400/20 transition-all duration-500" />
        <div className="absolute -bottom-8 -left-8 w-24 h-24 bg-violet-400/10 dark:bg-violet-400/5 rounded-full blur-2xl" />

        <div className="relative flex items-center gap-4">
          {/* Moon icon */}
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shadow-lg shadow-indigo-500/25 flex-shrink-0">
            <Moon className="w-6 h-6 text-white" />
          </div>

          {/* Content */}
          <div className="flex-1 min-w-0">
            <h3 className="text-sm font-semibold text-indigo-900 dark:text-indigo-200">
              Sleep Tracker
            </h3>
            {todaySleepLog ? (
              <div className="flex items-center gap-1.5 mt-0.5">
                <Clock className="w-3.5 h-3.5 text-indigo-500/70 dark:text-indigo-400/70" />
                <span className="text-sm font-medium text-indigo-700 dark:text-indigo-300">
                  {Math.floor(todaySleepLog.duration_minutes / 60)}h{" "}
                  {todaySleepLog.duration_minutes % 60}m
                </span>
                <span className="text-xs text-indigo-500/60 dark:text-indigo-400/50 ml-1">
                  {todaySleepLog.sleep_time} → {todaySleepLog.wake_time}
                </span>
              </div>
            ) : (
              <p className="text-xs text-indigo-600/60 dark:text-indigo-400/50 mt-0.5">
                Tap to log your sleep for {format(activeDate, "MMM d")}
              </p>
            )}
          </div>

          {/* Action indicator */}
          <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-white/60 dark:bg-white/10 flex items-center justify-center group-hover:bg-white/90 dark:group-hover:bg-white/20 transition-all">
            <Plus className="w-4 h-4 text-indigo-600 dark:text-indigo-300" />
          </div>
        </div>
      </motion.div>

      {/* Modal */}
      <HabitFormModal
        isOpen={showModal}
        onClose={handleClose}
        onSubmit={handleSubmit}
        editHabit={editingHabit}
      />

      <SleepInputModal
        isOpen={isSleepModalOpen}
        onClose={() => setIsSleepModalOpen(false)}
        onSave={handleSleepSave}
        isLoading={sleepLoading}
        initialBedtime={todaySleepLog?.sleep_time || "22:45"}
        initialWakeTime={todaySleepLog?.wake_time || "05:00"}
      />
    </div>
  );
}
