#!/usr/bin/env python3
import os
import re

# Patterns to disable with comments for common intentional issues
disable_patterns = [
    # Unused parameters in functions (SC2034)
    (r'^(\s*)(PREFIX=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(CIDR=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(SUB_DOMAIN=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(KEY_NAME=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(CSV=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(ENV=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(PARAMETERS=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(TEMPLATE=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(STACK_NAME=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(TAG=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(VPC_ID=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
    (r'^(\s*)(SUBNET_ID=\$\d)', r'\1\2\n\1# shellcheck disable=SC2034'),
]

def fix_file(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    # Add disable comments for unused parameters
    for pattern, replacement in disable_patterns:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
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
