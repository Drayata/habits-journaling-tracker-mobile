import 'package:isar/isar.dart';

part 'habit_log.g.dart';

@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int habitId;

  @Index()
  late DateTime date;

  @Index(unique: true, replace: true)
  late String habitDateKey;

  late bool isCompleted;

  static String generateKey(int habitId, DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$habitId:$year-$month-$day';
  }
}
