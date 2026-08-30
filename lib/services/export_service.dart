import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/journal_entry.dart';
import '../models/sleep_log.dart';

class ExportService {
  final Isar _isar;

  ExportService(this._isar);

  Future<void> exportHabits() async {
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

    await _exportCsvAndShare('habits_export.csv', rows);
  }

  Future<void> exportHabitLogs() async {
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

    await _exportCsvAndShare('habit_logs_export.csv', rows);
  }

  Future<void> exportJournalEntries() async {
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

    await _exportCsvAndShare('journal_export.csv', rows);
  }

  Future<void> _exportCsvAndShare(
    String fileName,
    List<List<dynamic>> rows,
  ) async {
    final csvString = const CsvEncoder().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);
    
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Exported $fileName');
  }

  Future<void> exportBackupToJson() async {
    final habits = await _isar.habits.where().findAll();
    final logs = await _isar.habitLogs.where().findAll();
    final journals = await _isar.journalEntrys.where().findAll();
    final sleeps = await _isar.sleepLogs.where().findAll();

    final backupData = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => {
            'id': h.id,
            'name': h.name,
            'description': h.description,
            'createdAt': h.createdAt.toIso8601String(),
          }).toList(),
      'habitLogs': logs.map((l) => {
            'id': l.id,
            'habitId': l.habitId,
            'date': l.date.toIso8601String(),
            'isCompleted': l.isCompleted,
          }).toList(),
      'journals': journals.map((j) => {
            'id': j.id,
            'date': j.date.toIso8601String(),
            'title': j.title,
            'content': j.content,
            'mood': j.mood,
          }).toList(),
      'sleepLogs': sleeps.map((s) => {
            'id': s.id,
            'date': s.date.toIso8601String(),
            'hours': s.hours,
            'notes': s.notes,
          }).toList(),
    };

    final jsonString = jsonEncode(backupData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/habitflow_backup.json');
    await file.writeAsString(jsonString);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'HabitFlow Full Backup');
  }

  Future<bool> restoreBackupFromJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isEmpty || result.single.path == null) {
        return false; // User canceled
      }

      final file = File(result.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!data.containsKey('habits') ||
          !data.containsKey('habitLogs') ||
          !data.containsKey('journals') ||
          !data.containsKey('sleepLogs')) {
        throw const FormatException('Invalid backup structure');
      }

      final habits = (data['habits'] as List).map((h) => Habit()
        ..id = h['id']
        ..name = h['name']
        ..description = h['description']
        ..createdAt = DateTime.parse(h['createdAt'])).toList();

      final logs = (data['habitLogs'] as List).map((l) => HabitLog()
        ..id = l['id']
        ..habitId = l['habitId']
        ..date = DateTime.parse(l['date'])
        ..isCompleted = l['isCompleted']).toList();

      final journals = (data['journals'] as List).map((j) => JournalEntry()
        ..id = j['id']
        ..date = DateTime.parse(j['date'])
        ..title = j['title']
        ..content = j['content']
        ..mood = j['mood']).toList();

      final sleeps = (data['sleepLogs'] as List).map((s) => SleepLog()
        ..id = s['id']
        ..date = DateTime.parse(s['date'])
        ..hours = s['hours']
        ..notes = s['notes']).toList();

      // Write all to Isar, replacing existing data if conflicts occur (putAll)
      await _isar.writeTxn(() async {
        await _isar.habits.putAll(habits);
        await _isar.habitLogs.putAll(logs);
        await _isar.journalEntrys.putAll(journals);
        await _isar.sleepLogs.putAll(sleeps);
      });

      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
