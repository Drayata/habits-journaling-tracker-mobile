import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';

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
      [HabitSchema, HabitLogSchema, JournalEntrySchema],
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
