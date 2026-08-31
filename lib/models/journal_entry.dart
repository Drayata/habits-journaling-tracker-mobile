import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  late String content;

  late int mood;

  DateTime? updatedAt;
}
