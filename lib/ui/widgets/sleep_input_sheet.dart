import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sleep_provider.dart';

class SleepInputSheet extends ConsumerStatefulWidget {
  const SleepInputSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SleepInputSheet(),
    );
  }

  @override
  ConsumerState<SleepInputSheet> createState() => _SleepInputSheetState();
}

class _SleepInputSheetState extends ConsumerState<SleepInputSheet> {
  double _hours = 7.0;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todaySleepAsync = ref.read(todaySleepProvider);
      if (todaySleepAsync.hasValue && todaySleepAsync.value != null) {
        setState(() {
          _hours = todaySleepAsync.value!.hours;
          _notesController.text = todaySleepAsync.value!.notes ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sleep Tracker',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'How much did you sleep last night?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '${_hours.toStringAsFixed(1)} hours',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: primary,
                  ),
            ),
          ),
          Slider(
            value: _hours,
            min: 0,
            max: 16,
            divisions: 32,
            activeColor: primary,
            onChanged: (value) => setState(() => _hours = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(sleepProvider.notifier).addOrUpdateSleep(
                      DateTime.now(),
                      _hours,
                      _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                    );
                Navigator.pop(context);
              },
              child: const Text('Save Sleep Log'),
            ),
          ),
        ],
      ),
    );
  }
}
