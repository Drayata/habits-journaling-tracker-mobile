import re

def fix_habits_screen():
    path = r'c:\Projects\habits-journaling-tracker-mobile\lib\ui\screens\habits_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add missing import
    if 'app_localizations.dart' not in content:
        content = content.replace("import '../../models/habit.dart';", "import 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart';\nimport '../../models/habit.dart';")

    # Remove all definitions of _NewHabitDialog and _NewHabitDialogState
    # and then we'll append exactly one at the end.
    
    # We will split the file by 'class _NewHabitDialog extends ConsumerStatefulWidget {'
    # keep the first part, then just append the correct block at the end.
    parts = content.split('class _NewHabitDialog extends ConsumerStatefulWidget {')
    if len(parts) > 1:
        # the first part contains everything before the first _NewHabitDialog
        new_content = parts[0].strip() + "\n\n"
        
        # Append exactly one instance of the class
        good_dialog = """class _NewHabitDialog extends ConsumerStatefulWidget {
  const _NewHabitDialog();

  @override
  ConsumerState<_NewHabitDialog> createState() => _NewHabitDialogState();
}

class _NewHabitDialogState extends ConsumerState<_NewHabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(habitsProvider.notifier).addHabit(
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSaveHabit(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.newHabit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.habitName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.add),
        ),
      ],
    );
  }
}
"""
        new_content += good_dialog
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)

def fix_journal_screen():
    path = r'c:\Projects\habits-journaling-tracker-mobile\lib\ui\screens\journal_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove `import 'habits_screen.dart' show DateBar;`
    content = re.sub(r"import 'habits_screen\.dart' show DateBar;\n", "", content)
    
    # Fix `dateOnly`
    if 'extension DateOnlyExt' not in content:
        ext = """
extension DateOnlyExt on DateTime {
  DateTime dateOnly() => DateTime(year, month, day);
}
"""
        content += ext
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_stats_provider():
    path = r'c:\Projects\habits-journaling-tracker-mobile\lib\providers\stats_provider.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # fix A value of type 'int' can't be assigned to a variable of type 'String'
    # search for it and replace with toString()
    content = content.replace("entry.moodScore", "entry.moodScore.toString()")
    content = content.replace("entry.moodScore.toString().toString()", "entry.moodScore.toString()")
    content = content.replace("sleep.hours", "sleep.hours.toString()")
    content = content.replace("sleep.hours.toString().toString()", "sleep.hours.toString()")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_habits_screen()
fix_journal_screen()
fix_stats_provider()
print("Fixed files.")
