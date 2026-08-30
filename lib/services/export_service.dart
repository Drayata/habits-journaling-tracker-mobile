import 'dart:io';

import 'package:csv/csv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';

class ExportService {
  final Isar _isar;

  ExportService(this._isar);

  Future<String> exportHabits() async {
    final habits = await _isar.habits.where().findAll();

    final rows = <List<dynamic>>[
      ['id', 'name', 'description', 'createdAt'],
      ...habits.map((h) => [
            h.id,
            h.name,
            h.description ?? '',
            h.createdAt.toIso8601String(),
          ]),
    ];

    return _writeCsvFile('habits_export.csv', rows);
  }

  Future<String> exportHabitLogs() async {
    final logs = await _isar.habitLogs.where().findAll();

    final rows = <List<dynamic>>[
      ['id', 'habitId', 'date', 'isCompleted'],
      ...logs.map((l) => [
            l.id,
            l.habitId,
            l.date.toIso8601String(),
            l.isCompleted,
          ]),
    ];

    return _writeCsvFile('habit_logs_export.csv', rows);
  }

  Future<String> exportJournalEntries() async {
    final entries = await _isar.journalEntrys.where().findAll();

    final rows = <List<dynamic>>[
      ['id', 'date', 'title', 'content', 'mood'],
      ...entries.map((e) => [
            e.id,
            e.date.toIso8601String(),
            e.title,
            e.content,
            e.mood,
          ]),
    ];

    return _writeCsvFile('journal_export.csv', rows);
  }

  Future<String> _writeCsvFile(
    String fileName,
    List<List<dynamic>> rows,
  ) async {
    final csvString = const CsvEncoder().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);
    return file.path;
  }
}
