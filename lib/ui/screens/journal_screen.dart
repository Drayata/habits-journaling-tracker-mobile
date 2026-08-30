import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../theme.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  static void showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedMood = 'Good';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'Mood',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Great', child: Text('Great')),
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(value: 'Neutral', child: Text('Neutral')),
                    DropdownMenuItem(value: 'Bad', child: Text('Bad')),
                    DropdownMenuItem(value: 'Terrible', child: Text('Terrible')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedMood = v ?? 'Good'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                if (title.isNotEmpty && content.isNotEmpty) {
                  ref.read(journalProvider.notifier).addEntry(
                        title: title,
                        content: content,
                        mood: selectedMood,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No journal entries yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to write your first entry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _JournalTile(entry: entries[index], ref: ref),
        );
      },
    );
  }
}

class _JournalTile extends StatelessWidget {
  final JournalEntry entry;
  final WidgetRef ref;

  const _JournalTile({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showDeleteDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _moodColor(entry.mood).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _moodIcon(entry.mood),
                          size: 14,
                          color: _moodColor(entry.mood),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.mood,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _moodColor(entry.mood),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(entry.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(journalProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _moodColor(String mood) {
    return switch (mood) {
      'Great' => const Color(0xFF10B981),
      'Good' => const Color(0xFF3B82F6),
      'Neutral' => const Color(0xFF6B7280),
      'Bad' => const Color(0xFFF59E0B),
      'Terrible' => const Color(0xFFEF4444),
      _ => const Color(0xFF6B7280),
    };
  }

  IconData _moodIcon(String mood) {
    return switch (mood) {
      'Great' => Icons.sentiment_very_satisfied,
      'Good' => Icons.sentiment_satisfied,
      'Neutral' => Icons.sentiment_neutral,
      'Bad' => Icons.sentiment_dissatisfied,
      'Terrible' => Icons.sentiment_very_dissatisfied,
      _ => Icons.sentiment_neutral,
    };
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
