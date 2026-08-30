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
    // Wait for database to be ready
    await ref.watch(databaseProvider.future);
    return _isar.habits.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> addHabit({required String name, String? description}) async {
    final habit = Habit()
      ..name = name
      ..description = description
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() => _isar.habits.put(habit));

    state = AsyncData(
      await _isar.habits.where().sortByCreatedAtDesc().findAll(),
    );
  }

  Future<void> updateHabit(Habit habit) async {
    await _isar.writeTxn(() => _isar.habits.put(habit));

    state = AsyncData(
      await _isar.habits.where().sortByCreatedAtDesc().findAll(),
    );
  }

  Future<void> deleteHabit(int id) async {
    await _isar.writeTxn(() async {
      // Delete associated logs first
      await _isar.habitLogs.filter().habitIdEqualTo(id).deleteAll();
      await _isar.habits.delete(id);
    });

    state = AsyncData(
      await _isar.habits.where().sortByCreatedAtDesc().findAll(),
    );
  }

  Future<void> toggleLog({
    required int habitId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final existing = await _isar.habitLogs
        .filter()
        .habitIdEqualTo(habitId)
        .dateEqualTo(dateOnly)
        .findFirst();

    await _isar.writeTxn(() async {
      if (existing != null) {
        existing.isCompleted = !existing.isCompleted;
        await _isar.habitLogs.put(existing);
      } else {
        final log = HabitLog()
          ..habitId = habitId
          ..date = dateOnly
          ..isCompleted = true;
        await _isar.habitLogs.put(log);
      }
    });

    // Re-read state so listeners react
    state = AsyncData(
      await _isar.habits.where().sortByCreatedAtDesc().findAll(),
    );
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) async {
    return _isar.habitLogs
        .filter()
        .habitIdEqualTo(habitId)
        .sortByDateDesc()
        .findAll();
  }

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _isar.habitLogs.filter().dateEqualTo(dateOnly).findAll();
  }
}
