import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/habit.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/habits_provider.dart';
import '../theme.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  static void showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(habitsProvider.notifier).addHabit(
                      name: name,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      descController.dispose();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final completedIdsAsync = ref.watch(todayCompletedHabitIdsProvider);

    return habitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (habits) {
        if (habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create your first habit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          );
        }

        final completedIds = completedIdsAsync.valueOrNull ?? {};

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final habit = habits[index];
            final isCompleted = completedIds.contains(habit.id);
            return _HabitTile(habit: habit, isCompleted: isCompleted);
          },
        );
      },
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;

  const _HabitTile({required this.habit, required this.isCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showDeleteDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          habit.description!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(habitsProvider.notifier).toggleLog(
                        habitId: habit.id,
                        date: DateTime.now(),
                      );
                },
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted
                      ? AppTheme.successColor
                      : Colors.grey.shade400,
                  size: 32,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.name}" and all its logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
