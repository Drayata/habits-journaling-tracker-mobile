import 'package:isar/isar.dart';

part 'habit.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String name;

  String? description;

  @Index()
  late DateTime createdAt;

  bool isArchived = false;
  
  DateTime? archivedAt;
  
  int position = 0;
  
  String frequency = 'daily';
  
  String colorHint = '#10b981';
}
