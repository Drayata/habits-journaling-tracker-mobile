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
    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habits',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatHeaderDate(selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // DateBar
        _DateBar(selectedDate: selectedDate),
        const SizedBox(height: 8),
        // Habits list
        Expanded(
          child: habitsAsync.when(
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first habit',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade400,
                                ),
                      ),
                    ],
                  ),
                );
              }

              final completedIds = completedIdsAsync.valueOrNull ?? {};
              final completedCount = habits.where((h) => completedIds.contains(h.id)).length;

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: habits.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final isCompleted =
                            completedIds.contains(habit.id);
                        return _HabitTile(
                          habit: habit,
                          isCompleted: isCompleted,
                          selectedDate: selectedDate,
                        );
                      },
                    ),
                  ),
                  // Progress summary bar
                  if (habits.isNotEmpty)
                    _ProgressBar(
                      completed: completedCount,
                      total: habits.length,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatHeaderDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

// ============================================================
// DateBar - horizontal scrollable date picker (15 days)
// ============================================================

class _DateBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const _DateBar({required this.selectedDate});

  @override
  ConsumerState<_DateBar> createState() => _DateBarState();
}

class _DateBarState extends ConsumerState<_DateBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCenter());
  }

  @override
  void didUpdateWidget(covariant _DateBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCenter());
    }
  }

  void _scrollToCenter() {
    if (!_scrollController.hasClients) return;
    // Active date is at index 7 (center of 15)
    const itemWidth = 60.0;
    const spacing = 8.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetOffset =
        7 * (itemWidth + spacing) - (screenWidth / 2) + (itemWidth / 2);
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeDate = widget.selectedDate;

    // Generate 15 days centered on active date
    final days = List.generate(15, (i) {
      return activeDate.add(Duration(days: i - 7));
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final dayOnly = DateTime(day.year, day.month, day.day);
          final isActive = dayOnly == activeDate;
          final isToday = dayOnly == today;

          return _DateChip(
            day: dayOnly,
            isActive: isActive,
            isToday: isToday,
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = dayOnly;
            },
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime day;
  final bool isActive;
  final bool isToday;
  final VoidCallback onTap;

  const _DateChip({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    Color bgColor;
    Color textColor;
    Color subtextColor;
    BoxBorder? border;

    if (isActive) {
      bgColor = AppTheme.primaryColor;
      textColor = Colors.white;
      subtextColor = Colors.white70;
    } else if (isToday) {
      bgColor = AppTheme.primaryColor.withValues(alpha: 0.08);
      textColor = AppTheme.primaryColor;
      subtextColor = AppTheme.primaryColor.withValues(alpha: 0.6);
      border = Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3));
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      subtextColor = Colors.grey.shade500;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayAbbr[day.weekday - 1],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subtextColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              monthAbbr[day.month - 1],
              style: TextStyle(
                fontSize: 10,
                color: subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HabitTile
// ============================================================

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;
  final DateTime selectedDate;

  const _HabitTile({
    required this.habit,
    required this.isCompleted,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showDeleteDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        date: selectedDate,
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

// ============================================================
// Progress Bar (bottom summary)
// ============================================================

class _ProgressBar extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressBar({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final rate = total > 0 ? (completed / total) : 0.0;
    final percentage = (rate * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Progress",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            ),
          ),
        ],
      ),
    );
  }
}
