import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/journal_entry.dart';
import 'database_provider.dart';

final journalProvider =
    AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);

class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  Isar get _isar => ref.read(databaseProvider).requireValue;

  @override
  Future<List<JournalEntry>> build() async {
    await ref.watch(databaseProvider.future);
    return _isar.journalEntrys.where().sortByDateDesc().findAll();
  }

  Future<void> addEntry({
    required String title,
    required String content,
    required String mood,
    DateTime? date,
  }) async {
    final entry = JournalEntry()
      ..title = title
      ..content = content
      ..mood = mood
      ..date = date ?? DateTime.now();

    await _isar.writeTxn(() => _isar.journalEntrys.put(entry));

    state = AsyncData(
      await _isar.journalEntrys.where().sortByDateDesc().findAll(),
    );
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _isar.writeTxn(() => _isar.journalEntrys.put(entry));

    state = AsyncData(
      await _isar.journalEntrys.where().sortByDateDesc().findAll(),
    );
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() => _isar.journalEntrys.delete(id));

    state = AsyncData(
      await _isar.journalEntrys.where().sortByDateDesc().findAll(),
    );
  }

  Future<List<JournalEntry>> search(String query) async {
    if (query.isEmpty) {
      return _isar.journalEntrys.where().sortByDateDesc().findAll();
    }

    return _isar.journalEntrys
        .filter()
        .contentContains(query, caseSensitive: false)
        .or()
        .titleContains(query, caseSensitive: false)
        .sortByDateDesc()
        .findAll();
  }
}
