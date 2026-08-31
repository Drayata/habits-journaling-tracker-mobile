import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journal_entry.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/journal_provider.dart';
import '../theme.dart';
import 'habits_screen.dart' show DateBar; // Re-use DateBar
import 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _contentController = TextEditingController();
  Timer? _debounceTimer;
  int? _currentMood;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    setState(() {
      _isSaved = false;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveEntry();
    });
  }

  Future<void> _saveEntry() async {
    if (!mounted) return;
    final date = ref.read(selectedDateProvider);
    final content = _contentController.text.trim();

    // Do not save if both are empty
    if (content.isEmpty && _currentMood == null) return;

    setState(() => _isSaving = true);
    
    try {
      await ref.read(journalProvider.notifier).saveEntry(
            title: '', // React doesn't use title for daily journal
            content: content,
            mood: _currentMood,
            date: date,
          );
      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isSaved = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSave(e.toString()))),
        );
      }
    }
  }

  void _setMood(int mood) {
    setState(() => _currentMood = mood);
    _saveEntry();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isFutureDate = selectedDate.isAfter(dateOnly(DateTime.now()));
    final l10n = AppLocalizations.of(context)!;
    
    ref.listen<AsyncValue<JournalEntry?>>(selectedDateJournalProvider, (previous, next) {
      // When we navigate to a new date or data loads, update the controller if it's not focused
      next.whenData((entry) {
        final newContent = entry?.content ?? '';
        if (_contentController.text != newContent && !FocusScope.of(context).hasFocus) {
          _contentController.text = newContent;
        }
        if (_currentMood != entry?.mood) {
          setState(() {
            _currentMood = entry?.mood;
          });
        }
      });
    });

    final journalAsync = ref.watch(selectedDateJournalProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(l10n.journal),
            floating: true,
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (_isSaved && !_isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: Icon(Icons.check, color: AppTheme.successColor),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: DateBar(selectedDate: selectedDate),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MoodSelector(
                  selectedMood: _currentMood,
                  onMoodSelected: isFutureDate ? (_) {} : _setMood,
                  enabled: !isFutureDate,
                  l10n: l10n,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.book_outlined, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              l10n.todaysEntry,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        journalAsync.when(
                          loading: () => const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => SizedBox(
                            height: 300,
                            child: Center(child: Text(l10n.errorMessage(e.toString()))),
                          ),
                          data: (_) => TextField(
                            controller: _contentController,
                            enabled: !isFutureDate,
                            maxLines: null,
                            minLines: 12,
                            decoration: InputDecoration(
                              hintText: isFutureDate 
                                ? l10n.cannotAddJournalFuture
                                : l10n.journalHint,
                              border: InputBorder.none,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    l10n.journalAutoSaveHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ),
                const SizedBox(height: 100), // padding for keyboard
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;
  final bool enabled;
  final AppLocalizations l10n;

  const _MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
    this.enabled = true,
    required this.l10n,
  });

  String _getMoodLabel(int index) {
    switch(index) {
      case 1: return l10n.moodAwful;
      case 2: return l10n.moodBad;
      case 3: return l10n.moodOkay;
      case 4: return l10n.moodGood;
      case 5: return l10n.moodGreat;
      default: return '';
    }
  }

  static const _moods = [
    (1, '😢'),
    (2, '😕'),
    (3, '😐'),
    (4, '🙂'),
    (5, '😄'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.howAreYouFeeling,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((mood) {
                final isSelected = selectedMood == mood.$1;
                return Expanded(
                  child: InkWell(
                    onTap: enabled ? () => onMoodSelected(mood.$1) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood.$2,
                            style: TextStyle(
                              fontSize: isSelected ? 28 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMoodLabel(mood.$1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

extension DateOnlyExt on DateTime {
  DateTime dateOnly() => DateTime(year, month, day);
}
