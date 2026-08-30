import 'package:isar/isar.dart';

part 'habit_log.g.dart';

@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int habitId;

  @Index()
  late DateTime date;

  late bool isCompleted;
}
