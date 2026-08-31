import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit_log.dart';
import 'database_provider.dart';
import 'habits_provider.dart';

class DashboardStats {
  final int totalHabits;
  final int completedToday;

  const DashboardStats({
    required this.totalHabits,
    required this.completedToday,
  });

  double get completionRate =>
      totalHabits == 0 ? 0.0 : completedToday / totalHabits;
}

/// Shared date state used by Habits screen (DateBar) and dashboard providers.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Month offset for stats navigation (0 = current month, -1 = last month, etc.)
final statsMonthOffsetProvider = StateProvider<int>((ref) => 0);

/// Derives the month range from the offset.
final statsMonthRangeProvider = Provider<DateTimeRange>((ref) {
  final offset = ref.watch(statsMonthOffsetProvider);
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month + offset, 1);
  final lastOfMonth = DateTime(now.year, now.month + offset + 1, 0);
  return DateTimeRange(start: firstOfMonth, end: lastOfMonth);
});

final todayStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final habits = await ref.watch(habitsProvider.future);
  final isar = ref.read(databaseProvider).requireValue;
  final selectedDate = ref.watch(selectedDateProvider);

  final completedLogs = await isar.habitLogs
      .filter()
      .dateEqualTo(selectedDate)
      .isCompletedEqualTo(true)
      .findAll();

  return DashboardStats(
    totalHabits: habits.length,
    completedToday: completedLogs.length,
  );
});

final todayCompletedHabitIdsProvider = FutureProvider<Set<int>>((ref) async {
  await ref.watch(habitsProvider.future);
  final isar = ref.read(databaseProvider).requireValue;
  final selectedDate = ref.watch(selectedDateProvider);

  final logs = await isar.habitLogs
      .filter()
      .dateEqualTo(selectedDate)
      .isCompletedEqualTo(true)
      .findAll();

  return logs.map((l) => l.habitId).toSet();
});

final heatmapDataProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  await ref.watch(habitsProvider.future);
  final isar = ref.read(databaseProvider).requireValue;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 29));

  final logs = await isar.habitLogs
      .filter()
      .dateBetween(start, today)
      .isCompletedEqualTo(true)
      .findAll();

  final map = <DateTime, int>{};
  for (final log in logs) {
    final key = DateTime(log.date.year, log.date.month, log.date.day);
    map[key] = (map[key] ?? 0) + 1;
  }

  return map;
});
