import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../services/database_service.dart';

final databaseProvider = FutureProvider<Isar>((ref) async {
  final isar = await DatabaseService.instance.init();
  ref.onDispose(() => DatabaseService.instance.close());
  return isar;
});
