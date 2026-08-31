import os
import glob

repo_path = r"C:\Projects\habits-journaling-tracker-mobile"
files = glob.glob(os.path.join(repo_path, 'lib/**/*.dart'), recursive=True) + glob.glob(os.path.join(repo_path, 'test/**/*.dart'), recursive=True)

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    if 'package:flutter_gen/gen_l10n/app_localizations.dart' in content:
        content = content.replace('package:flutter_gen/gen_l10n/app_localizations.dart', 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart')
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Updated {f}")
