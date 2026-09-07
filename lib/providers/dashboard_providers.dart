import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit_log.dart';
import '../utils/date_utils.dart';
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
  return DateTime.now().logicalDay();
});

/// Month offset for stats navigation (0 = current month, -1 = last month, etc.)
final statsMonthOffsetProvider = StateProvider<int>((ref) => 0);

/// Derives the month range from the offset.
final statsMonthRangeProvider = Provider<DateTimeRange>((ref) {
  final offset = ref.watch(statsMonthOffsetProvider);
  final now = DateTime.now().logicalDay();
  final firstOfMonth = DateTime(now.year, now.month + offset, 1);
  final lastOfMonth = DateTime(now.year, now.month + offset + 1, 0);
  return DateTimeRange(start: firstOfMonth, end: lastOfMonth);
});

final todayStatsProvider = StreamProvider<DashboardStats>((ref) {
  final isar = ref.watch(databaseProvider).requireValue;
  final selectedDate = ref.watch(selectedDateProvider);
  final habitsAsync = ref.watch(habitsProvider);

  final totalHabits = habitsAsync.valueOrNull?.length ?? 0;

  return isar.habitLogs
      .filter()
      .dateEqualTo(selectedDate)
      .isCompletedEqualTo(true)
      .watch(fireImmediately: true)
      .map((logs) {
    return DashboardStats(
      totalHabits: totalHabits,
      completedToday: logs.length,
    );
  });
});

final todayCompletedHabitIdsProvider = StreamProvider<Set<int>>((ref) {
  final isar = ref.watch(databaseProvider).requireValue;
  final selectedDate = ref.watch(selectedDateProvider);

  return isar.habitLogs
      .filter()
      .dateEqualTo(selectedDate)
      .isCompletedEqualTo(true)
      .watch(fireImmediately: true)
      .map((logs) => logs.map((l) => l.habitId).toSet());
});

// Top-level function for compute
Map<DateTime, int> _buildHeatmap(List<HabitLog> logs) {
  final map = <DateTime, int>{};
  for (final log in logs) {
    final key = log.date;
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
}

final heatmapDataProvider = StreamProvider<Map<DateTime, int>>((ref) {
  final isar = ref.watch(databaseProvider).requireValue;
  final today = DateTime.now().logicalDay();
  final start = today.subtract(const Duration(days: 29));

  return isar.habitLogs
      .filter()
      .dateBetween(start, today)
      .isCompletedEqualTo(true)
      .watch(fireImmediately: true)
      .asyncMap((logs) => compute(_buildHeatmap, logs));
});

