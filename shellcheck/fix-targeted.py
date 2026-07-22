#!/usr/bin/env python3
import os
import re
import sys

def fix_file(path):
    with open(path, 'r') as f:
        content = f.read()
    original = content

    # Fix SC2091: Remove $() from cat/awk/sed/grep pipelines that are not assignments
    # Only fix lines that start with $(
    content = re.sub(r'^\$\(cat\s+', 'cat ', content, flags=re.MULTILINE)
    content = re.sub(r'^\$\(grep\s+', 'grep ', content, flags=re.MULTILINE)

    # Fix SC2027 / SC2086: "prefix"${VAR}"suffix" -> "prefix${VAR}suffix"
    # Also handle similar malformed quoted strings
    content = re.sub(r'"(\$\{?[\w]+\}?)"', lambda m: m.group(1), content)
    # Handle patterns like "prefix"${VAR}"suffix" -> "prefix${VAR}suffix"
    content = re.sub(r'("[^"]*)"(\$\{?[\w]+\}?)"([^"]*")', r'\1\2\3', content)

    # Fix SC1036/SC1088: account=$"(get_account...) -> account=$(get_account...)
    content = re.sub(r'=\$"\(', r'=$(', content)

    # Fix SC1072/SC1073: "prefix"${VAR}"suffix" already handled above

    # Fix SC1078: "prefix"${VAR}... -> "prefix${VAR}..."
    # Unclosed quotes like ${VAR"[*] -> ${VAR[*]}
    content = re.sub(r'(\$\{?[\w]+\}?)\"\[', r'\1[', content)
    content = re.sub(r'(\$\{?[\w]+\}?)\"\)', r'\1)', content)
    content = re.sub(r'(\$\{?[\w]+\}?)"(\s)', r'\1\2', content)

    # Fix SC2155: export x=$(cmd) -> x=$(cmd); export x
    # and local x=$(cmd) already done

    # Fix SC2088: source "~... -> source "$HOME/...
    content = re.sub(r'source\s+"~/', 'source "$HOME/', content)

    # Fix SC2066: for var in "${ARR}"; -> for var in ${ARR};
    content = re.sub(r'for\s+\w+\s+in\s+"\$\{(\w+)\}";', r'for \1 in ${ARR};', content)

    if content != original:
        with open(path, 'w') as f:
            f.write(content)
        print(f'Fixed: {path}')

for root, dirs, files in os.walk('.'):
    for f in files:
        if f.endswith('.sh'):
            fix_file(os.path.join(root, f))
