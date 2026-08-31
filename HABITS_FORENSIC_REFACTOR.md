# Forensic Refactor — habits-journaling-tracker-mobile

## Forensic Report

1. `dashboard_providers.dart` treated `habitsProvider.future` as the invalidation source for completion changes while reading `habitLogs` imperatively from Isar. A habit toggle changes `HabitLog`, not `Habit`, so the dependency graph was semantically wrong. `habits_provider.dart` attempted to compensate by re-reading and re-emitting the unchanged habit list after every toggle.
2. `stats_provider.dart` repeated the same disconnect: completion records were queried directly from Isar, but there was no reactive dependency on the `habitLogs` collection. It also used `habits.length` as every historical day's denominator, including habits created after that day.
3. `database_service.dart` omitted `SleepLogSchema` from `Isar.open(...)` although `sleepProvider` and stats query `isar.sleepLogs`. This is a runtime database schema defect.
4. `heatmap_grid.dart` manually computed a seven-column cell size and then clamped it to a hard 28px minimum. If the real constraint cannot contain `7 * 28 + gaps`, overflow is guaranteed. The Flutter heatmap also represented a rolling 30-day strip, while React renders the selected calendar month with leading/trailing weekday padding and completion intensity based on completed/active habits.
5. `dashboard_screen.dart` contained a fixed legend `Row` with multiple fixed gaps/text labels, which can overflow narrow cards. Progress-ring sizing was based on full screen width instead of the card's actual constraints.
6. Flutter already contained a local `_DateBar`; it was not actually missing. The parity defect was that the habits list still showed every habit for retroactive dates, so dates before a habit's `createdAt` used the wrong denominator and exposed habits that did not yet exist.
7. Flutter stats had only previous/next arrows and blocked navigation beyond the current month. React's `DateContext`/`MonthNavigator` supports independent selected day, selected month/year, arbitrary month picking, and return-to-current-month.
8. Full archive parity is impossible with the current Flutter `Habit` schema because it contains only `name`, `description`, and `createdAt`. React's `isHabitActiveOnDate` also depends on `is_archived` and `archived_at`. This refactor implements the representable historical rule (`createdAt <= target day`) without inventing schema data.

## Refactor Architecture

- `selectedDateProvider`: global day state for Habits, Dashboard progress, and date-aware sleep logging.
- `selectedMonthProvider`: global first-of-month state matching the React monthly context.
- `habitLogsProvider`: Isar collection watch stream; this is the real reactive source for completion changes.
- `selectedDateStatsProvider`, `selectedDateCompletedHabitIdsProvider`, and `heatmapDataProvider`: pure reactive derivations.
- `statsDataProvider`: combines reactive habits/logs/journals/sleep data and recalculates active-habit denominators per day.
- `HeatmapGrid`: true seven-column calendar grid; no manually clamped cell width.
- All interactive controls introduced/changed use at least 48x48 logical-pixel targets.

## Validation Note

The execution environment used for this forensic pass does not contain the Flutter/Dart SDK, so `flutter analyze` and device tests could not be executed here. Static source checks were performed for balanced delimiters, stale provider references, and dependency consistency. Run `flutter analyze` and `flutter test` in the project SDK environment before release.

## Complete Modified Files

### `lib/providers/dashboard_providers.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/sleep_log.dart';
import 'database_provider.dart';
import 'habits_provider.dart';
import 'sleep_provider.dart';

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime monthOnly(DateTime value) => DateTime(value.year, value.month, 1);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// The current Isar schema only stores `createdAt` for a habit. This therefore
/// implements the historical subset that the Flutter schema can represent:
/// a habit is active on/after its creation date. Archive/frequency semantics
/// require adding those fields to Habit and regenerating the Isar schema.
bool isHabitActiveOnDate(Habit habit, DateTime date) {
  final target = dateOnly(date);
  final created = dateOnly(habit.createdAt);
  final isSleepTracker = habit.name.trim().toLowerCase() == 'sleep tracker';
  return !isSleepTracker && !created.isAfter(target);
}

class DashboardStats {
  final DateTime date;
  final int totalHabits;
  final int completedCount;

  const DashboardStats({
    required this.date,
    required this.totalHabits,
    required this.completedCount,
  });

  double get completionRate =>
      totalHabits == 0 ? 0.0 : completedCount / totalHabits;
}

class HeatmapDayData {
  final DateTime date;
  final int completedCount;
  final int activeHabitCount;

  const HeatmapDayData({
    required this.date,
    required this.completedCount,
    required this.activeHabitCount,
  });

  double get completionRate => activeHabitCount == 0
      ? 0.0
      : (completedCount / activeHabitCount).clamp(0.0, 1.0).toDouble();
}

class HeatmapData {
  final DateTime monthStart;
  final DateTime monthEnd;
  final Map<DateTime, HeatmapDayData> days;

  const HeatmapData({
    required this.monthStart,
    required this.monthEnd,
    required this.days,
  });

  int get daysInMonth => monthEnd.day;
}

/// Global day selection. Habits, dashboard progress, and date-aware widgets
/// all derive from this provider instead of calling DateTime.now() directly.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return dateOnly(DateTime.now());
});

/// Global month selection matching the React DateContext monthly API.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return monthOnly(DateTime.now());
});

final statsMonthRangeProvider = Provider<DateTimeRange>((ref) {
  final month = monthOnly(ref.watch(selectedMonthProvider));
  final nextMonth = DateTime(month.year, month.month + 1, 1);
  return DateTimeRange(
    start: month,
    end: nextMonth.subtract(const Duration(days: 1)),
  );
});

final isCurrentMonthProvider = Provider<bool>((ref) {
  final selected = ref.watch(selectedMonthProvider);
  return isSameMonth(selected, DateTime.now());
});

/// Isar is the source of truth for completion records. Watching the collection
/// makes habit toggles reactive even though Habit objects themselves did not
/// change. This removes the previous false dependency on habitsProvider.
final habitLogsProvider = StreamProvider<List<HabitLog>>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  yield* isar.habitLogs.where().watch(fireImmediately: true);
});

final selectedDateActiveHabitsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(habitsProvider).whenData(
        (habits) => habits
            .where((habit) => isHabitActiveOnDate(habit, selectedDate))
            .toList(growable: false),
      );
});

final selectedDateCompletedHabitIdsProvider =
    Provider<AsyncValue<Set<int>>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(habitLogsProvider).whenData((logs) {
    return logs
        .where(
          (log) => log.isCompleted && isSameDay(log.date, selectedDate),
        )
        .map((log) => log.habitId)
        .toSet();
  });
});

final selectedDateStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final habitsAsync = ref.watch(habitsProvider);
  final logsAsync = ref.watch(habitLogsProvider);

  return habitsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (habits) => logsAsync.when(
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
      data: (logs) {
        final activeHabits = habits
            .where((habit) => isHabitActiveOnDate(habit, selectedDate))
            .toList(growable: false);
        final activeIds = activeHabits.map((habit) => habit.id).toSet();
        final completedIds = logs
            .where(
              (log) =>
                  log.isCompleted &&
                  isSameDay(log.date, selectedDate) &&
                  activeIds.contains(log.habitId),
            )
            .map((log) => log.habitId)
            .toSet();

        return AsyncData(
          DashboardStats(
            date: selectedDate,
            totalHabits: activeHabits.length,
            completedCount: completedIds.length,
          ),
        );
      },
    ),
  );
});

final selectedDateSleepProvider = Provider<AsyncValue<SleepLog?>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(sleepProvider).whenData((logs) {
    for (final log in logs) {
      if (isSameDay(log.date, selectedDate)) {
        return log;
      }
    }
    return null;
  });
});

final heatmapDataProvider = Provider<AsyncValue<HeatmapData>>((ref) {
  final range = ref.watch(statsMonthRangeProvider);
  final habitsAsync = ref.watch(habitsProvider);
  final logsAsync = ref.watch(habitLogsProvider);

  return habitsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (habits) => logsAsync.when(
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
      data: (logs) {
        final result = <DateTime, HeatmapDayData>{};

        for (var dayNumber = 1; dayNumber <= range.end.day; dayNumber++) {
          final day = DateTime(range.start.year, range.start.month, dayNumber);
          final activeHabitIds = habits
              .where((habit) => isHabitActiveOnDate(habit, day))
              .map((habit) => habit.id)
              .toSet();

          final completedIds = logs
              .where(
                (log) =>
                    log.isCompleted &&
                    isSameDay(log.date, day) &&
                    activeHabitIds.contains(log.habitId),
              )
              .map((log) => log.habitId)
              .toSet();

          result[day] = HeatmapDayData(
            date: day,
            completedCount: completedIds.length,
            activeHabitCount: activeHabitIds.length,
          );
        }

        return AsyncData(
          HeatmapData(
            monthStart: range.start,
            monthEnd: range.end,
            days: result,
          ),
        );
      },
    ),
  );
});
```

### `lib/providers/stats_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../models/sleep_log.dart';
import 'dashboard_providers.dart';
import 'database_provider.dart';
import 'habits_provider.dart';

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
  final DateTime date;
  final double hours;

  const SleepTrendPoint({
    required this.label,
    required this.date,
    required this.hours,
  });
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


final _journalEntriesForStatsProvider =
    StreamProvider<List<JournalEntry>>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  yield* isar.journalEntrys.where().watch(fireImmediately: true);
});

final _sleepLogsForStatsProvider = StreamProvider<List<SleepLog>>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  yield* isar.sleepLogs.where().watch(fireImmediately: true);
});

final statsDataProvider = Provider<AsyncValue<StatsData>>((ref) {
  final monthRange = ref.watch(statsMonthRangeProvider);
  final habitsAsync = ref.watch(habitsProvider);
  final habitLogsAsync = ref.watch(habitLogsProvider);
  final journalsAsync = ref.watch(_journalEntriesForStatsProvider);
  final sleepAsync = ref.watch(_sleepLogsForStatsProvider);

  return habitsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (habits) => habitLogsAsync.when(
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
      data: (habitLogs) => journalsAsync.when(
        loading: () => const AsyncLoading(),
        error: (error, stackTrace) => AsyncError(error, stackTrace),
        data: (journals) => sleepAsync.when(
          loading: () => const AsyncLoading(),
          error: (error, stackTrace) => AsyncError(error, stackTrace),
          data: (sleepLogs) => AsyncData(
            _buildStats(
              habits: habits,
              habitLogs: habitLogs,
              journals: journals,
              sleepLogs: sleepLogs,
              monthStart: monthRange.start,
              monthEnd: monthRange.end,
            ),
          ),
        ),
      ),
    ),
  );
});

StatsData _buildStats({
  required List<Habit> habits,
  required List<HabitLog> habitLogs,
  required List<JournalEntry> journals,
  required List<SleepLog> sleepLogs,
  required DateTime monthStart,
  required DateTime monthEnd,
}) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final completedByDay = <DateTime, Set<int>>{};
  for (final log in habitLogs) {
    if (!log.isCompleted) continue;
    final day = dateOnly(log.date);
    if (day.isBefore(monthStart) || day.isAfter(monthEnd)) continue;
    completedByDay.putIfAbsent(day, () => <int>{}).add(log.habitId);
  }

  final sleepByDay = <DateTime, double>{};
  for (final log in sleepLogs) {
    final day = dateOnly(log.date);
    if (day.isBefore(monthStart) || day.isAfter(monthEnd)) continue;
    sleepByDay[day] = log.hours;
  }

  final monthJournals = journals.where((entry) {
    final day = dateOnly(entry.date);
    return !day.isBefore(monthStart) && !day.isAfter(monthEnd);
  }).toList(growable: false);

  final completionTrend = <DayTrend>[];
  var totalRate = 0.0;
  var bestRate = 0;
  var bestDayLabel = '-';
  var activeDays = 0;

  for (var dayNumber = 1; dayNumber <= monthEnd.day; dayNumber++) {
    final day = DateTime(monthStart.year, monthStart.month, dayNumber);
    final activeHabitIds = habits
        .where((habit) => isHabitActiveOnDate(habit, day))
        .map((habit) => habit.id)
        .toSet();

    final completedIds = completedByDay[day] ?? const <int>{};
    final validCompletedCount =
        completedIds.where(activeHabitIds.contains).length;
    final rate = activeHabitIds.isEmpty
        ? 0
        : ((validCompletedCount / activeHabitIds.length) * 100).round();
    final label = '${monthNames[day.month - 1]} ${day.day}';

    completionTrend.add(
      DayTrend(
        label: label,
        date: day,
        completedCount: validCompletedCount,
        totalHabits: activeHabitIds.length,
        rate: rate.toDouble(),
      ),
    );

    totalRate += rate;
    if (validCompletedCount > 0) activeDays++;
    if (rate > bestRate) {
      bestRate = rate;
      bestDayLabel = label;
    }
  }

  final avgCompletion = completionTrend.isEmpty
      ? 0
      : (totalRate / completionTrend.length).round();

  final sleepTrend = <SleepTrendPoint>[];
  var totalSleepHours = 0.0;
  var sleepDays = 0;
  for (var dayNumber = 1; dayNumber <= monthEnd.day; dayNumber++) {
    final day = DateTime(monthStart.year, monthStart.month, dayNumber);
    final hours = sleepByDay[day] ?? 0.0;
    sleepTrend.add(
      SleepTrendPoint(
        label: '${monthNames[day.month - 1]} ${day.day}',
        date: day,
        hours: hours,
      ),
    );
    if (hours > 0) {
      totalSleepHours += hours;
      sleepDays++;
    }
  }

  final avgSleepHours = sleepDays == 0 ? 0.0 : totalSleepHours / sleepDays;
  final avgSleepWholeHours = avgSleepHours.floor();
  final avgSleepMinutes = ((avgSleepHours - avgSleepWholeHours) * 60).round();
  final avgSleep = '${avgSleepWholeHours}h ${avgSleepMinutes}m';

  final moodBuckets = <String, List<double>>{};
  for (final journal in monthJournals) {
    final day = dateOnly(journal.date);
    final activeHabitIds = habits
        .where((habit) => isHabitActiveOnDate(habit, day))
        .map((habit) => habit.id)
        .toSet();
    final completedIds = completedByDay[day] ?? const <int>{};
    final validCompletedCount =
        completedIds.where(activeHabitIds.contains).length;
    final rate = activeHabitIds.isEmpty
        ? 0.0
        : (validCompletedCount / activeHabitIds.length) * 100;
    moodBuckets.putIfAbsent(journal.mood, () => <double>[]).add(rate);
  }

  const moodOrder = ['Terrible', 'Bad', 'Neutral', 'Good', 'Great'];
  final moodCorrelation = moodOrder.map((mood) {
    final values = moodBuckets[mood] ?? const <double>[];
    final average = values.isEmpty
        ? 0.0
        : values.reduce((left, right) => left + right) / values.length;
    return MoodCorrelation(
      mood: mood,
      avgCompletion: average,
      entries: values.length,
    );
  }).toList(growable: false);

  return StatsData(
    avgCompletion: avgCompletion,
    bestDayLabel: bestDayLabel,
    bestDayRate: bestRate,
    activeDays: activeDays,
    daysInMonth: monthEnd.day,
    avgSleep: avgSleep,
    totalJournals: monthJournals.length,
    completionTrend: completionTrend,
    sleepTrend: sleepTrend,
    moodCorrelation: moodCorrelation,
  );
}
```

### `lib/providers/habits_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import 'database_provider.dart';

final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  Isar get _isar => ref.read(databaseProvider).requireValue;

  @override
  Future<List<Habit>> build() async {
    await ref.watch(databaseProvider.future);
    return _loadHabits();
  }

  Future<List<Habit>> _loadHabits() {
    return _isar.habits.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> addHabit({
    required String name,
    String? description,
  }) async {
    final habit = Habit()
      ..name = name
      ..description = description
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() => _isar.habits.put(habit));
    state = AsyncData(await _loadHabits());
  }

  Future<void> updateHabit(Habit habit) async {
    await _isar.writeTxn(() => _isar.habits.put(habit));
    state = AsyncData(await _loadHabits());
  }

  Future<void> deleteHabit(int id) async {
    await _isar.writeTxn(() async {
      await _isar.habitLogs.filter().habitIdEqualTo(id).deleteAll();
      await _isar.habits.delete(id);
    });

    state = AsyncData(await _loadHabits());
  }

  Future<void> toggleLog({
    required int habitId,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final matches = await _isar.habitLogs
        .filter()
        .habitIdEqualTo(habitId)
        .dateEqualTo(normalizedDate)
        .findAll();

    final currentlyCompleted = matches.any((log) => log.isCompleted);

    await _isar.writeTxn(() async {
      if (matches.isEmpty) {
        final log = HabitLog()
          ..habitId = habitId
          ..date = normalizedDate
          ..isCompleted = true;
        await _isar.habitLogs.put(log);
        return;
      }

      final canonical = matches.first;
      canonical.isCompleted = !currentlyCompleted;
      await _isar.habitLogs.put(canonical);

      if (matches.length > 1) {
        final duplicateIds = matches.skip(1).map((log) => log.id).toList();
        await _isar.habitLogs.deleteAll(duplicateIds);
      }
    });

    // Intentionally do not rewrite habitsProvider state here. HabitLog changes
    // are observed by habitLogsProvider's Isar stream in dashboard_providers.
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) {
    return _isar.habitLogs
        .filter()
        .habitIdEqualTo(habitId)
        .sortByDateDesc()
        .findAll();
  }

  Future<List<HabitLog>> getLogsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _isar.habitLogs.filter().dateEqualTo(normalizedDate).findAll();
  }
}
```

### `lib/services/database_service.dart`

```dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../models/sleep_log.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService _instance = DatabaseService._();
  static DatabaseService get instance => _instance;

  Isar? _isar;

  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<Isar> init() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        HabitSchema,
        HabitLogSchema,
        JournalEntrySchema,
        SleepLogSchema,
      ],
      directory: dir.path,
    );

    return _isar!;
  }

  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
```

### `lib/ui/screens/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../theme.dart';
import '../widgets/heatmap_grid.dart';
import '../widgets/month_navigator.dart';
import '../widgets/progress_ring.dart';
import '../widgets/sleep_input_sheet.dart';
import 'profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final statsAsync = ref.watch(selectedDateStatsProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final sleepAsync = ref.watch(selectedDateSleepProvider);
    final isCurrentMonth = ref.watch(isCurrentMonthProvider);
    final monthRange = ref.watch(statsMonthRangeProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 56,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.person_outline),
                color: AppTheme.primaryColor,
                iconSize: 26,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _CenteredContent(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLongDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: _CenteredContent(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MonthNavigator(),
          ),
        ),
        if (!isCurrentMonth)
          SliverToBoxAdapter(
            child: _CenteredContent(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Viewing ${_formatMonth(monthRange.start)}. Daily check-ins still follow the selected date from Habits.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _CenteredContent(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSameDay(selectedDate, DateTime.now())
                                ? "Today's Progress"
                                : 'Progress · ${_formatShortDate(selectedDate)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Use today',
                          onPressed: isSameDay(selectedDate, DateTime.now())
                              ? null
                              : () {
                                  ref.read(selectedDateProvider.notifier).state =
                                      dateOnly(DateTime.now());
                                },
                          icon: const Icon(Icons.today_outlined),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    statsAsync.when(
                      loading: () => const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _InlineError(
                        message: 'Unable to load progress: $error',
                      ),
                      data: (stats) => LayoutBuilder(
                        builder: (context, constraints) {
                          final available = constraints.maxWidth;
                          final ringSize =
                              (available * 0.52).clamp(128.0, 184.0).toDouble();
                          return Column(
                            children: [
                              ProgressRing(
                                progress: stats.completionRate,
                                progressColor: AppTheme.successColor,
                                size: ringSize,
                                strokeWidth: (ringSize * 0.075)
                                    .clamp(10.0, 14.0)
                                    .toDouble(),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${stats.completedCount} of ${stats.totalHabits} habits',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _CenteredContent(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => SleepInputSheet.show(
                  context,
                  date: selectedDate,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 88),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bedtime_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sleep · ${_formatShortDate(selectedDate)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              sleepAsync.when(
                                loading: () => Text(
                                  'Loading…',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                error: (_, __) => Text(
                                  'Unable to load sleep log',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.red.shade600),
                                ),
                                data: (sleep) => Text(
                                  sleep == null
                                      ? 'Tap to log sleep'
                                      : '${sleep.hours.toStringAsFixed(1)} hours logged',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _CenteredContent(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Heatmap · ${_formatMonth(monthRange.start)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    heatmapAsync.when(
                      loading: () => const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _InlineError(
                        message: 'Unable to load heatmap: $error',
                      ),
                      data: (data) => HeatmapGrid(data: data),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String _formatLongDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _CenteredContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CenteredContent({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red.shade700,
            ),
      ),
    );
  }
}
```

### `lib/ui/screens/habits_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/habit.dart';
import '../../models/sleep_log.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/habits_provider.dart';
import '../theme.dart';
import '../widgets/sleep_input_sheet.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  static void showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Habit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              await ref.read(habitsProvider.notifier).addHabit(
                    name: name,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      descriptionController.dispose();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final activeHabitsAsync = ref.watch(selectedDateActiveHabitsProvider);
    final completedIdsAsync =
        ref.watch(selectedDateCompletedHabitIdsProvider);
    final sleepAsync = ref.watch(selectedDateSleepProvider);

    final activeHabits = activeHabitsAsync.valueOrNull ?? const <Habit>[];
    final completedIds = completedIdsAsync.valueOrNull ?? const <int>{};
    final completedCount = activeHabits
        .where((habit) => completedIds.contains(habit.id))
        .length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habits',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatHeaderDate(selectedDate)} · $completedCount/${activeHabits.length} done',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Today',
                    onPressed: isSameDay(selectedDate, DateTime.now())
                        ? null
                        : () {
                            ref.read(selectedDateProvider.notifier).state =
                                dateOnly(DateTime.now());
                          },
                    icon: const Icon(Icons.today_outlined),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ),
            _DateBar(selectedDate: selectedDate),
            const SizedBox(height: 4),
            Expanded(
              child: activeHabitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: 'Unable to load habits: $error',
                ),
                data: (habits) => completedIdsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => _ErrorState(
                    message: 'Unable to load completion data: $error',
                  ),
                  data: (ids) => CustomScrollView(
                    slivers: [
                      if (habits.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                            child: _EmptyHabitsState(
                              selectedDate: selectedDate,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index.isOdd) {
                                  return const SizedBox(height: 8);
                                }
                                final habit = habits[index ~/ 2];
                                return _HabitTile(
                                  habit: habit,
                                  isCompleted: ids.contains(habit.id),
                                  selectedDate: selectedDate,
                                );
                              },
                              childCount: habits.length * 2 - 1,
                            ),
                          ),
                        ),
                      if (habits.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _ProgressCard(
                              date: selectedDate,
                              completed: habits
                                  .where((habit) => ids.contains(habit.id))
                                  .length,
                              total: habits.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: _SleepCard(
                            date: selectedDate,
                            sleepAsync: sleepAsync,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatHeaderDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _DateBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const _DateBar({required this.selectedDate});

  @override
  ConsumerState<_DateBar> createState() => _DateBarState();
}

class _DateBarState extends ConsumerState<_DateBar> {
  static const _itemWidth = 56.0;
  static const _spacing = 8.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerActiveDate());
  }

  @override
  void didUpdateWidget(covariant _DateBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerActiveDate());
    }
  }

  void _centerActiveDate() {
    if (!_scrollController.hasClients || !mounted) return;
    final viewportWidth = _scrollController.position.viewportDimension;
    final desired = 7 * (_itemWidth + _spacing) -
        (viewportWidth - _itemWidth) / 2;
    final offset = desired
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List<DateTime>.generate(
      15,
      (index) => dateOnly(
        widget.selectedDate.add(Duration(days: index - 7)),
      ),
    );
    final today = dateOnly(DateTime.now());

    return SizedBox(
      height: 76,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: _spacing),
        itemBuilder: (context, index) {
          final day = days[index];
          return _DateChip(
            day: day,
            isActive: isSameDay(day, widget.selectedDate),
            isToday: isSameDay(day, today),
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = day;
            },
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime day;
  final bool isActive;
  final bool isToday;
  final VoidCallback onTap;

  const _DateChip({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final background = isActive
        ? AppTheme.primaryColor
        : isToday
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Colors.white;
    final foreground = isActive
        ? Colors.white
        : isToday
            ? AppTheme.primaryColor
            : Colors.grey.shade700;
    final secondary = isActive ? Colors.white70 : Colors.grey.shade500;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 56,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 68),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryColor
                  : isToday
                      ? AppTheme.primaryColor.withValues(alpha: 0.30)
                      : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabels[day.weekday - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              Text(
                monthLabels[day.month - 1],
                style: TextStyle(fontSize: 10, color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;
  final DateTime selectedDate;

  const _HabitTile({
    required this.habit,
    required this.isCompleted,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showDeleteDialog(context, ref),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (habit.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 3),
                        Text(
                          habit.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isCompleted ? 'Mark incomplete' : 'Mark complete',
                  onPressed: () async {
                    await ref.read(habitsProvider.notifier).toggleLog(
                          habitId: habit.id,
                          date: selectedDate,
                        );
                  },
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: isCompleted
                        ? AppTheme.successColor
                        : Colors.grey.shade400,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.name}" and all its logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final DateTime date;
  final int completed;
  final int total;

  const _ProgressCard({
    required this.date,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0.0 : completed / total;
    final percentage = (rate * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSameDay(date, DateTime.now())
                        ? "Today's Progress"
                        : 'Daily Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final DateTime date;
  final AsyncValue<SleepLog?> sleepAsync;

  const _SleepCard({
    required this.date,
    required this.sleepAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => SleepInputSheet.show(context, date: date),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bedtime_outlined,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sleep Tracker',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      sleepAsync.when(
                        loading: () => Text(
                          'Loading…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        error: (_, __) => Text(
                          'Unable to load sleep log',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red.shade600,
                                  ),
                        ),
                        data: (sleep) => Text(
                          sleep == null
                              ? 'Tap to log sleep for ${_shortDate(date)}'
                              : '${sleep.hours.toStringAsFixed(1)} hours logged',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _EmptyHabitsState extends StatelessWidget {
  final DateTime selectedDate;

  const _EmptyHabitsState({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'No active habits for this date',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Habits created after the selected date are intentionally excluded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
        ),
      ),
    );
  }
}
```

### `lib/ui/screens/stats_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../../providers/stats_provider.dart';
import '../theme.dart';
import '../widgets/heatmap_grid.dart';
import '../widgets/month_navigator.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsDataProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final monthRange = ref.watch(statsMonthRangeProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CenteredContent(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Habit insights for ${_formatMonth(monthRange.start)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: _CenteredContent(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MonthNavigator(),
          ),
        ),
        statsAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load statistics: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          data: (stats) => SliverToBoxAdapter(
            child: _CenteredContent(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryGrid(stats: stats),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.trending_up,
                    title: 'Daily Completion Rate',
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  _CompletionChart(data: stats.completionTrend),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.bedtime_outlined,
                    title: 'Sleep Duration (Hours)',
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 10),
                  _SleepChart(data: stats.sleepTrend),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.favorite_outline,
                    title: 'Mood vs. Habit Completion',
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Average completion rate grouped by daily mood',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _MoodChart(data: stats.moodCorrelation),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    icon: Icons.grid_view_rounded,
                    title: 'Activity Heatmap · ${_formatMonth(monthRange.start)}',
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: heatmapAsync.when(
                        loading: () => const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Text(
                          'Unable to load heatmap: $error',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red.shade700,
                                  ),
                        ),
                        data: (data) => HeatmapGrid(data: data),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatsData stats;

  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 132,
          children: [
            _StatCard(
              title: 'Avg Completion',
              value: '${stats.avgCompletion}%',
              icon: Icons.trending_up,
              color: AppTheme.primaryColor,
            ),
            _StatCard(
              title: 'Best Day (${stats.bestDayRate}%)',
              value: stats.bestDayLabel,
              icon: Icons.star_outline,
              color: AppTheme.successColor,
            ),
            _StatCard(
              title: 'Active Days',
              value: '${stats.activeDays}/${stats.daysInMonth}',
              icon: Icons.calendar_today_outlined,
              color: const Color(0xFFF59E0B),
            ),
            _StatCard(
              title: 'Avg Sleep',
              value: stats.avgSleep,
              icon: Icons.bedtime_outlined,
              color: Colors.deepPurple,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _CompletionChart extends StatelessWidget {
  final List<DayTrend> data;

  const _CompletionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No completion data');
    }

    return _ScrollableBarChart(
      itemCount: data.length,
      barColor: AppTheme.primaryColor,
      valueAt: (index) => data[index].rate.clamp(0.0, 100.0).toDouble() / 100.0,
      valueLabelAt: (index) => '${data[index].rate.round()}%',
      axisLabelAt: (index) => '${data[index].date.day}',
      tooltipAt: (index) =>
          '${data[index].label}: ${data[index].completedCount}/${data[index].totalHabits} (${data[index].rate.round()}%)',
    );
  }
}

class _SleepChart extends StatelessWidget {
  final List<SleepTrendPoint> data;

  const _SleepChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No sleep data');
    }

    var maxHours = 8.0;
    for (final point in data) {
      if (point.hours > maxHours) maxHours = point.hours;
    }

    return _ScrollableBarChart(
      itemCount: data.length,
      barColor: Colors.deepPurple,
      valueAt: (index) =>
          maxHours == 0
              ? 0.0
              : (data[index].hours / maxHours)
                  .clamp(0.0, 1.0)
                  .toDouble(),
      valueLabelAt: (index) =>
          data[index].hours == 0 ? '' : data[index].hours.toStringAsFixed(1),
      axisLabelAt: (index) => '${data[index].date.day}',
      tooltipAt: (index) =>
          '${data[index].label}: ${data[index].hours.toStringAsFixed(1)}h',
    );
  }
}

class _ScrollableBarChart extends StatelessWidget {
  final int itemCount;
  final Color barColor;
  final double Function(int index) valueAt;
  final String Function(int index) valueLabelAt;
  final String Function(int index) axisLabelAt;
  final String Function(int index) tooltipAt;

  const _ScrollableBarChart({
    required this.itemCount,
    required this.barColor,
    required this.valueAt,
    required this.valueLabelAt,
    required this.axisLabelAt,
    required this.tooltipAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = itemCount * 34.0;
            final chartWidth = contentWidth < constraints.maxWidth
                ? constraints.maxWidth
                : contentWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(itemCount, (index) {
                    final ratio = valueAt(index).clamp(0.0, 1.0).toDouble();
                    final valueLabel = valueLabelAt(index);
                    return Expanded(
                      child: Tooltip(
                        message: tooltipAt(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 18,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    valueLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: barColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 132 * ratio + 2,
                                constraints: const BoxConstraints(minWidth: 8),
                                decoration: BoxDecoration(
                                  color: barColor.withValues(alpha: 0.82),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 16,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    axisLabelAt(index),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MoodChart extends StatelessWidget {
  final List<MoodCorrelation> data;

  const _MoodChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasData = data.any((item) => item.entries > 0);
    if (!hasData) {
      return const _EmptyChart(
        message: 'No mood data. Add journal entries with moods.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        child: SizedBox(
          height: 210,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final ratio =
                  (item.avgCompletion / 100).clamp(0.0, 1.0).toDouble();
              return Expanded(
                child: Tooltip(
                  message:
                      '${item.mood}: ${item.avgCompletion.round()}% across ${item.entries} entries',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 18,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.entries == 0
                                  ? ''
                                  : '${item.avgCompletion.round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.successColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 132 * ratio + 2,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.84),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 28,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.mood,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 160,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CenteredContent({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

### `lib/ui/widgets/heatmap_grid.dart`

```dart
import 'package:flutter/material.dart';

import '../../providers/dashboard_providers.dart';
import '../theme.dart';

class HeatmapGrid extends StatelessWidget {
  final HeatmapData data;

  const HeatmapGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final firstWeekday = data.monthStart.weekday; // Monday = 1
    final leadingPadding = firstWeekday - 1;
    final rawCellCount = leadingPadding + data.daysInMonth;
    final trailingPadding = (7 - (rawCellCount % 7)) % 7;
    final cellCount = rawCellCount + trailingPadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (label) => Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingPadding + 1;
            if (dayNumber < 1 || dayNumber > data.daysInMonth) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }

            final date = DateTime(
              data.monthStart.year,
              data.monthStart.month,
              dayNumber,
            );
            final dayData = data.days[date] ??
                HeatmapDayData(
                  date: date,
                  completedCount: 0,
                  activeHabitCount: 0,
                );
            final now = dateOnly(DateTime.now());
            final isToday = isSameDay(date, now);
            final isFuture = date.isAfter(now);
            final background = _backgroundColor(dayData, isFuture);
            final foreground = _foregroundColor(dayData, isFuture);

            return Tooltip(
              message:
                  '${_monthShort(date.month)} ${date.day}: ${dayData.completedCount}/${dayData.activeHabitCount} completed',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday
                        ? AppTheme.successColor
                        : isFuture
                            ? Colors.grey.shade300
                            : Colors.transparent,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(
              'Less',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
            ),
            _LegendSwatch(color: Colors.grey.shade100),
            _LegendSwatch(
              color: AppTheme.successColor.withValues(alpha: 0.25),
            ),
            _LegendSwatch(
              color: AppTheme.successColor.withValues(alpha: 0.45),
            ),
            _LegendSwatch(
              color: AppTheme.successColor.withValues(alpha: 0.7),
            ),
            const _LegendSwatch(color: AppTheme.successColor),
            Text(
              'More',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _backgroundColor(HeatmapDayData day, bool isFuture) {
    if (isFuture) return Colors.grey.shade50;
    if (day.completedCount == 0) return Colors.grey.shade100;
    if (day.activeHabitCount == 0) {
      return AppTheme.successColor.withValues(alpha: 0.25);
    }

    final ratio = day.completionRate;
    if (ratio <= 0.25) {
      return AppTheme.successColor.withValues(alpha: 0.25);
    }
    if (ratio <= 0.50) {
      return AppTheme.successColor.withValues(alpha: 0.45);
    }
    if (ratio <= 0.75) {
      return AppTheme.successColor.withValues(alpha: 0.70);
    }
    return AppTheme.successColor;
  }

  Color _foregroundColor(HeatmapDayData day, bool isFuture) {
    if (isFuture) return Colors.grey.shade400;
    if (day.completionRate > 0.5) return Colors.white;
    return Colors.grey.shade600;
  }

  String _monthShort(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;

  const _LegendSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
```

### `lib/ui/widgets/month_navigator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../theme.dart';

class MonthNavigator extends ConsumerWidget {
  const MonthNavigator({super.key});

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isCurrentMonth = ref.watch(isCurrentMonthProvider);
    final monthLabel =
        '${_monthNames[selectedMonth.month - 1]} ${selectedMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _NavButton(
              tooltip: 'Previous month',
              icon: Icons.chevron_left,
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).state = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                  1,
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showMonthPicker(context, ref, selectedMonth),
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppTheme.successColor,
                ),
                label: Text(
                  monthLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NavButton(
              tooltip: 'Next month',
              icon: Icons.chevron_right,
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).state = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                  1,
                );
              },
            ),
          ],
        ),
        if (!isCurrentMonth) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).state =
                    monthOnly(DateTime.now());
              },
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Current month'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
  ) async {
    var pickerYear = selectedMonth.year;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final now = DateTime.now();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _NavButton(
                          tooltip: 'Previous year',
                          icon: Icons.chevron_left,
                          onPressed: () => setState(() => pickerYear--),
                        ),
                        Expanded(
                          child: Text(
                            '$pickerYear',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _NavButton(
                          tooltip: 'Next year',
                          icon: Icons.chevron_right,
                          onPressed: () => setState(() => pickerYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 52,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = selectedMonth.year == pickerYear &&
                            selectedMonth.month == month;
                        final isNow = now.year == pickerYear && now.month == month;

                        return FilledButton.tonal(
                          onPressed: () {
                            ref.read(selectedMonthProvider.notifier).state =
                                DateTime(pickerYear, month, 1);
                            Navigator.of(sheetContext).pop();
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: isSelected
                                ? AppTheme.successColor
                                : isNow
                                    ? AppTheme.successColor.withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                            foregroundColor: isSelected
                                ? Colors.white
                                : isNow
                                    ? AppTheme.successColor
                                    : Theme.of(context).colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_monthNames[index].substring(0, 3)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

### `lib/ui/widgets/sleep_input_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../../providers/sleep_provider.dart';
import '../theme.dart';

class SleepInputSheet extends ConsumerStatefulWidget {
  final DateTime date;

  const SleepInputSheet({
    super.key,
    required this.date,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepInputSheet(date: dateOnly(date)),
    );
  }

  @override
  ConsumerState<SleepInputSheet> createState() => _SleepInputSheetState();
}

class _SleepInputSheetState extends ConsumerState<SleepInputSheet> {
  double _hours = 7.0;
  final _notesController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final logsAsync = ref.read(sleepProvider);
    final logs = logsAsync.valueOrNull;
    if (logs == null) return;

    for (final log in logs) {
      if (isSameDay(log.date, widget.date)) {
        _hours = log.hours;
        _notesController.text = log.notes ?? '';
        break;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sleep Tracker',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(widget.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  '${_hours.toStringAsFixed(1)} hours',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
              Slider(
                value: _hours,
                min: 0,
                max: 16,
                divisions: 32,
                activeColor: AppTheme.primaryColor,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _hours = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Sleep Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(sleepProvider.notifier).addOrUpdateSleep(
            widget.date,
            _hours,
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
```

