import 'package:isar/isar.dart';

part 'sleep_log.g.dart';

@collection
class SleepLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  late double hours;

  String? notes;
}
