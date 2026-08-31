import re

def fix_journal_screen():
    path = r'c:\Projects\habits-journaling-tracker-mobile\lib\ui\screens\journal_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # fix dateOnly
    content = content.replace('dateOnly()', 'DateTime.now().dateOnly()')
    # fix selectedDateJournalProvider
    if "import '../../providers/journal_provider.dart';" not in content:
        content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../providers/journal_provider.dart';")
    # fix DateBar
    content = content.replace('DateBar(', '_DateBar(')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_notification_service():
    path = r'c:\Projects\habits-journaling-tracker-mobile\lib\services\notification_service.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # fix identifier isn't defined for String
    content = content.replace('.identifier', '')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_journal_screen()
fix_notification_service()
print("Fixed final issues.")
