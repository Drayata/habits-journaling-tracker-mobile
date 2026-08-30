import 'package:isar/isar.dart';

part 'habit.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String name;

  String? description;

  @Index()
  late DateTime createdAt;
}
