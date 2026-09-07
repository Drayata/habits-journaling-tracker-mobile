import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../models/sleep_log.dart';

import 'dashboard_providers.dart';
import 'database_provider.dart';
import 'habits_provider.dart';
import 'journal_provider.dart';
import 'sleep_provider.dart';

class DayTrend {
  final String label;
  final DateTime date;
  final int completedCount;
  final int totalHabits;
  final double rate;

  const DayTrend({
    required this.label,
    required this.date,
    required this.completedCount,
    required this.totalHabits,
    required this.rate,
  });
}

class SleepTrendPoint {
  final String label;
  final double hours;

  const SleepTrendPoint({required this.label, required this.hours});
}

class MoodCorrelation {
  final String mood;
  final double avgCompletion;
  final int entries;

  const MoodCorrelation({
    required this.mood,
    required this.avgCompletion,
    required this.entries,
  });
}

class StatsData {
  final int avgCompletion;
  final String bestDayLabel;
  final int bestDayRate;
  final int activeDays;
  final int daysInMonth;
  final String avgSleep;
  final int totalJournals;
  final List<DayTrend> completionTrend;
  final List<SleepTrendPoint> sleepTrend;
  final List<MoodCorrelation> moodCorrelation;

  const StatsData({
    required this.avgCompletion,
    required this.bestDayLabel,
    required this.bestDayRate,
    required this.activeDays,
    required this.daysInMonth,
    required this.avgSleep,
    required this.totalJournals,
    required this.completionTrend,
    required this.sleepTrend,
    required this.moodCorrelation,
  });
}

class StatsPayload {
  final DateTime monthStart;
  final DateTime monthEnd;
  final int habitCount;
  final List<HabitLog> completionLogs;
  final List<SleepLog> sleepLogs;
  final List<JournalEntry> journals;

  StatsPayload({
    required this.monthStart,
    required this.monthEnd,
    required this.habitCount,
    required this.completionLogs,
    required this.sleepLogs,
    required this.journals,
  });
}

StatsData _computeStats(StatsPayload payload) {
  final monthStart = payload.monthStart;
  final monthEnd = payload.monthEnd;
  final totalDays = monthEnd.day;
  final habitCount = payload.habitCount;

  // Build per-day completion map
  final dayCompletionMap = <DateTime, int>{};
  for (final log in payload.completionLogs) {
    // Already normalized by logicalDay
    final key = log.date;
    dayCompletionMap[key] = (dayCompletionMap[key] ?? 0) + 1;
  }

  // Build per-day sleep map
  final sleepMap = <DateTime, double>{};
  for (final log in payload.sleepLogs) {
    final key = log.date;
    sleepMap[key] = log.hours;
  }

  // Build journal day -> mood map
  final journalMoodMap = <DateTime, String>{};
  const moodNames = ['Terrible', 'Bad', 'Neutral', 'Good', 'Great'];
  for (final j in payload.journals) {
    final key = j.date;
    if (j.mood >= 1 && j.mood <= 5) {
      journalMoodMap[key] = moodNames[j.mood - 1];
    }
  }

  // Month day names
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // 1. Completion trend
  final trend = <DayTrend>[];
  int totalRate = 0;
  int bestRate = 0;
  String bestLabel = '-';
  int activeDayCount = 0;

  for (int d = 0; d < totalDays; d++) {
    final day = DateTime(monthStart.year, monthStart.month, d + 1);
    final label = '${monthNames[day.month - 1]} ${day.day}';
    final dayCompleted = dayCompletionMap[day] ?? 0;
    final rate = habitCount > 0 ? ((dayCompleted / habitCount) * 100).round() : 0;

    trend.add(DayTrend(
      label: label,
      date: day,
      completedCount: dayCompleted,
      totalHabits: habitCount,
      rate: rate.toDouble(),
    ));

    totalRate += rate;
    if (dayCompleted > 0) activeDayCount++;
    if (rate > bestRate) {
      bestRate = rate;
      bestLabel = label;
    }
  }

  final avgCompletionRate =
      trend.isEmpty ? 0 : (totalRate / trend.length).round();

  // 2. Sleep trend for the month
  final sleepTrend = <SleepTrendPoint>[];
  double totalSleepHours = 0;
  int sleepDayCount = 0;
  for (int d = 0; d < totalDays; d++) {
    final day = DateTime(monthStart.year, monthStart.month, d + 1);
    final label = '${monthNames[day.month - 1]} ${day.day}';
    final hours = sleepMap[day] ?? 0.0;
    sleepTrend.add(SleepTrendPoint(label: label, hours: hours));
    if (hours > 0) {
      totalSleepHours += hours;
      sleepDayCount++;
    }
  }

  final avgSleepHours = sleepDayCount > 0 ? totalSleepHours / sleepDayCount : 0.0;
  final avgSleepH = avgSleepHours.floor();
  final avgSleepM = ((avgSleepHours - avgSleepH) * 60).round();
  final avgSleepStr = '${avgSleepH}h ${avgSleepM}m';

  // 3. Journals in this month
  final monthJournals = payload.journals.where((j) {
    return !j.date.isBefore(monthStart) && !j.date.isAfter(monthEnd);
  }).toList();

  // 4. Mood vs completion correlation
  final moodBuckets = <String, List<int>>{};
  for (final j in monthJournals) {
    final key = j.date;
    final dayCompleted = dayCompletionMap[key] ?? 0;
    final rate = habitCount > 0 ? ((dayCompleted / habitCount) * 100).round() : 0;
    if (j.mood >= 1 && j.mood <= 5) {
      moodBuckets.putIfAbsent(moodNames[j.mood - 1], () => []).add(rate);
    }
  }

  const moodOrder = ['Terrible', 'Bad', 'Neutral', 'Good', 'Great'];
  final moodCorrelation = moodOrder.map((mood) {
    final rates = moodBuckets[mood] ?? [];
    final avg = rates.isEmpty
        ? 0.0
        : rates.reduce((a, b) => a + b) / rates.length;
    return MoodCorrelation(
      mood: mood,
      avgCompletion: avg,
      entries: rates.length,
    );
  }).toList();

  return StatsData(
    avgCompletion: avgCompletionRate,
    bestDayLabel: bestLabel,
    bestDayRate: bestRate,
    activeDays: activeDayCount,
    daysInMonth: totalDays,
    avgSleep: avgSleepStr,
    totalJournals: monthJournals.length,
    completionTrend: trend,
    sleepTrend: sleepTrend,
    moodCorrelation: moodCorrelation,
  );
}

final statsDataProvider = FutureProvider<StatsData>((ref) async {
  final habits = await ref.watch(habitsProvider.future);
  final journals = await ref.watch(journalProvider.future);
  final sleepLogs = await ref.watch(sleepProvider.future);
  final monthRange = ref.watch(statsMonthRangeProvider);
  final isar = ref.read(databaseProvider).requireValue;

  final monthStart = monthRange.start;
  final monthEnd = monthRange.end;

  // Fetch completions for this month
  final completionLogs = await isar.habitLogs
      .filter()
      .dateBetween(monthStart, monthEnd)
      .isCompletedEqualTo(true)
      .findAll();

  final payload = StatsPayload(
    monthStart: monthStart,
    monthEnd: monthEnd,
    habitCount: habits.length,
    completionLogs: completionLogs,
    sleepLogs: sleepLogs,
    journals: journals,
  );

  return compute(_computeStats, payload);
});
