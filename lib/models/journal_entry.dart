import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  late String content;

  late String mood;
}
