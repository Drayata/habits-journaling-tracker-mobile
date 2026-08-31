import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/export_service.dart';
import '../theme.dart';
import 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAndSettings),
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
            l10n.myProfile,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.settings,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(context, ref, l10n),
          const SizedBox(height: 32),
          Text(
            l10n.dataManagement,
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
                  title: Text(l10n.exportDataToCsv),
                  subtitle: Text(l10n.habitsLogsAndJournals),
                  onTap: () => _exportToCsv(context, ref, l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(l10n.backupDataJson),
                  subtitle: Text(l10n.fullStructuredBackup),
                  onTap: () => _exportToJson(context, ref, l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(l10n.restoreData),
                  subtitle: Text(l10n.restoreFromJsonBackup),
                  onTap: () => _restoreFromJson(context, ref, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final settingsAsync = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: settingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.errorMessage(e.toString())),
        ),
        data: (settings) => Column(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              trailing: SegmentedButton<Locale>(
                segments: const [
                  ButtonSegment(value: Locale('en'), label: Text('EN')),
                  ButtonSegment(value: Locale('id'), label: Text('ID')),
                ],
                selected: {locale},
                onSelectionChanged: (Set<Locale> newSelection) {
                  ref.read(localeProvider.notifier).setLocale(newSelection.first);
                },
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: Text(l10n.dailyReminder),
              subtitle: Text(
                settings.isReminderEnabled
                    ? l10n.atTime(settings.reminderTime.format(context))
                    : l10n.off,
              ),
              value: settings.isReminderEnabled,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (value) async {
                await ref.read(settingsProvider.notifier).toggleReminder(value);
                if (value && context.mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: settings.reminderTime,
                  );
                  if (time != null) {
                    await ref
                        .read(settingsProvider.notifier)
                        .setReminderTime(time);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      await exportService.exportHabits();
      await exportService.exportHabitLogs();
      await exportService.exportJournalEntries();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.csvExportCompleted)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportToJson(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      await exportService.exportBackupToJson();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.backupCompleted)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.backupFailed(e.toString()))),
      );
    }
  }

  Future<void> _restoreFromJson(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isar = await ref.read(databaseProvider.future);
      final exportService = ExportService(isar);
      
      final success = await exportService.restoreBackupFromJson();
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.dataRestoredSuccessfully)),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.restoreCanceled)),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.restoreFailed(e.toString()))),
      );
    }
  }
}
