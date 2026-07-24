#!/usr/bin/env python3
import os
import re


def fix_file(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # Fix remaining SC2086 - generic quote all ${VAR} not already quoted
    # Be careful not to double-quote
    content = re.sub(r'(?<!")(\$\{?[\w]+\}?)(?!")', lambda m: '"' + m.group(1) + '"' if not m.group(1).startswith('"') else m.group(1), content)

    # Fix SC1091: Add disable for source with non-constant path not caught by SC1090
    content = re.sub(r'^(\s*source\s+)([^"\']*\$)', lambda m: m.group(1) + '"' + m.group(2) + '"' if '"' not in m.group(2) else m.group(0), content, flags=re.MULTILINE)
    # Add comment for source with tilde
    content = re.sub(r'^(\s*source\s+[^#\n]*~[^"\']*)$', lambda m: m.group(1) + '\n# shellcheck disable=SC1090,SC1091', content, flags=re.MULTILINE)

    # Fix SC2013: for accts in $(cat file) -> while read
    content = re.sub(
        r'for\s+(\w+)\s+in\s+\$\(cat\s+([^)]+)\);\s+do\s+(\$\w+)\s+\$(\w+);\s+done',
        r'while read -r \1; do \3 "\$"\4; done < \2',
        content
    )

    with open(filename, 'w') as f:
        f.write(content)

for root, dirs, files in os.walk('.'):
    for f in files:
        if f.endswith('.sh'):
            fix_file(os.path.join(root, f))
