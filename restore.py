import json
import os
import sys

transcript_path = r"C:\Users\fadhol\.gemini\antigravity-ide\brain\b40dfa4b-a7e6-43e8-a4e0-538d3c797107\.system_generated\logs\transcript_full.jsonl"
repo_path = r"C:\Projects\habits-journaling-tracker-mobile"

def _match(target):
    if not target or not target.endswith('.dart') and not target.endswith('.arb') and not target.endswith('.yaml') and not target.endswith('.kts'):
        return False
    return os.path.normpath(target).lower().startswith(repo_path.lower())

def normalize(s):
    return s.replace('\r\n', '\n')

def apply_write(args):
    target = args.get('TargetFile')
    content = args.get('CodeContent', '')
    if _match(target):
        print(f"Write {target}")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'w', encoding='utf-8') as f:
            f.write(normalize(content))

def apply_replace(args):
    target = args.get('TargetFile')
    if not _match(target):
        return
    print(f"Replace in {target}")
    if not os.path.exists(target):
        print(f"Skipping {target} because it does not exist")
        return
    with open(target, 'r', encoding='utf-8') as f:
        content = normalize(f.read())
    
    target_content = normalize(args.get('TargetContent', ''))
    replacement = normalize(args.get('ReplacementContent', ''))
    content = content.replace(target_content, replacement)
    
    with open(target, 'w', encoding='utf-8') as f:
        f.write(content)

def apply_multi_replace(args):
    target = args.get('TargetFile')
    if not _match(target):
        return
    print(f"Multi-replace in {target}")
    if not os.path.exists(target):
        print(f"Skipping {target} because it does not exist")
        return
    with open(target, 'r', encoding='utf-8') as f:
        content = normalize(f.read())
    
    chunks = args.get('ReplacementChunks', [])
    for chunk in chunks:
        target_content = normalize(chunk.get('TargetContent', ''))
        replacement = normalize(chunk.get('ReplacementContent', ''))
        content = content.replace(target_content, replacement)
        
    with open(target, 'w', encoding='utf-8') as f:
        f.write(content)

# We must restore fresh from git so we don't apply multiple times on broken files
os.system(f'git -C "{repo_path}" restore .')

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        if not line.strip(): continue
        try:
            entry = json.loads(line)
        except:
            continue
        if entry.get('type') == 'PLANNER_RESPONSE' and 'tool_calls' in entry:
            for tc in entry['tool_calls']:
                tool_name = tc.get('name')
                args = tc.get('args', {})
                if tool_name in ['default_api:write_to_file', 'write_to_file']:
                    apply_write(args)
                elif tool_name in ['default_api:replace_file_content', 'replace_file_content']:
                    apply_replace(args)
                elif tool_name in ['default_api:multi_replace_file_content', 'multi_replace_file_content']:
                    apply_multi_replace(args)

# After restoring, fix imports because we use synthetic-package: false
import glob
files = glob.glob(os.path.join(repo_path, 'lib/**/*.dart'), recursive=True) + glob.glob(os.path.join(repo_path, 'test/**/*.dart'), recursive=True)
for f_path in files:
    with open(f_path, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'package:flutter_gen/gen_l10n/app_localizations.dart' in content:
        content = content.replace('package:flutter_gen/gen_l10n/app_localizations.dart', 'package:habits_journaling_tracker_mobile/l10n/gen/app_localizations.dart')
        with open(f_path, 'w', encoding='utf-8') as f:
            f.write(content)

print("Restoration complete.")
