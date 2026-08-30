import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../services/export_service.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'My Profile',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Export Data to CSV'),
                  subtitle: const Text('Habits, logs, and journals'),
                  onTap: () => _exportToCsv(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('Backup Data (JSON)'),
                  subtitle: const Text('Full structured backup'),
                  onTap: () => _exportToJson(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore from JSON backup'),
                  onTap: () => _restoreFromJson(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      await exportService.exportHabits();
      await exportService.exportHabitLogs();
      await exportService.exportJournalEntries();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('CSV Export completed')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _exportToJson(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      await exportService.exportBackupToJson();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Backup completed')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreFromJson(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      
      final success = await exportService.restoreBackupFromJson();
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Data restored successfully')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Restore canceled')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }
}
