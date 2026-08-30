import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/database_provider.dart';
import 'ui/screens/main_layout.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HabitsJournalingApp()));
}

class HabitsJournalingApp extends StatelessWidget {
  const HabitsJournalingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits & Journal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends ConsumerWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);

    return dbAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Database error: $error')),
      ),
      data: (_) => const MainLayout(),
    );
  }
}
