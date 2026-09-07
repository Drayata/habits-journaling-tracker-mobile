import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/sleep_log.dart';
import '../utils/date_utils.dart';
import 'database_provider.dart';

final sleepProvider =
    AsyncNotifierProvider<SleepNotifier, List<SleepLog>>(SleepNotifier.new);

class SleepNotifier extends AsyncNotifier<List<SleepLog>> {
  Isar get _isar => ref.read(databaseProvider).requireValue;

  @override
  Future<List<SleepLog>> build() async {
    await ref.watch(databaseProvider.future);
    return _isar.sleepLogs.where().sortByDateDesc().findAll();
  }

  Future<void> addOrUpdateSleep(
      DateTime date, double hours, String? notes) async {
    final dateOnly = date.logicalDay();
    
    await _isar.writeTxn(() async {
      final existing =
          await _isar.sleepLogs.filter().dateEqualTo(dateOnly).findFirst();

      final log = existing ?? SleepLog()
        ..date = dateOnly;
      log.hours = hours;
      log.notes = notes;

      await _isar.sleepLogs.put(log);
    });

    state = AsyncData(
      await _isar.sleepLogs.where().sortByDateDesc().findAll(),
    );
  }
}

final todaySleepProvider = FutureProvider<SleepLog?>((ref) async {
  final logs = await ref.watch(sleepProvider.future);
  final now = DateTime.now();
  final today = now.logicalDay();
  
  try {
    return logs.firstWhere((log) => log.date == today);
  } catch (e) {
    return null;
  }
});
