#!/usr/bin/env python3
import os
import re
import sys

def fix_file(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    for i, line in enumerate(lines):
        original = line
        
        # Fix SC2162: Add -r to read
        if re.search(r'\bread\s+(?!\-r)', line):
            line = re.sub(r'\bread\s+', 'read -r ', line)
        
        # Fix SC2006: Replace backticks with $()
        # Simple pattern: avoid replacing inside strings that already use $()
        line = re.sub(r'(?<!\$)`([^`]+)`', r'$(\1)', line)
        
        # Fix SC1090: Add disable comment before source with variable
        if re.match(r'\s*source\s+[~$]', line) and 'shellcheck' not in line:
            indent = len(line) - len(line.lstrip())
            new_lines.append(' ' * indent + '# shellcheck disable=SC1090\n')
        
        # Fix SC2034: Add disable comment if variable appears unused
        # This is approximate - we just comment out obvious unused declarations
        # Actually better to just add disable comment before the line
        # We'll skip this for now and handle it separately
        
        # Fix SC2086: Quote variable expansions in specific commands
        # aws commands
        line = re.sub(r'(--profile\s+)(\$\{?[\w]+\}?)', r'\1"\2"', line)
        line = re.sub(r'(--role-arn=)(\$\{?[\w]+\}?)', r'\1"\2"', line)
        # rm commands
        line = re.sub(r'(\brm\s+)(\$\w+)', r'\1"\2"', line)
        # source paths
        line = re.sub(r'(source\s+)(\$\w+)', r'\1"\2"', line)
        # grep patterns
        line = re.sub(r'grep\s+([^"\']+\$\w+)', lambda m: m.group(0).replace(m.group(1), '"' + m.group(1) + '"'), line)
        
        new_lines.append(line)
    
    content = ''.join(new_lines)
    
    # Fix SC2155: local x=$(cmd) -> local x; x=$(cmd)
    content = re.sub(r'^(local\s+)(\w+=\$\([^)]+\))', r'\1\2; \2', content, flags=re.MULTILINE)
    
    # Fix SC2207: arr=($(cmd)) -> mapfile -t arr < <(cmd)
    content = re.sub(r'^(\s*)(\w+)=\(\$\(([^)]+)\)\)', r'\1mapfile -t \2 < <(\3)', content, flags=re.MULTILINE)
    
    # Fix SC2116 / SC2005: useless echo
    content = re.sub(r'^(\s*)echo\s+`', r'\1', content, flags=re.MULTILINE)
    content = re.sub(r'^(\s*)echo\s+\$\(', r'\1', content, flags=re.MULTILINE)
    
    with open(filename, 'w') as f:
        f.write(content)

for root, dirs, files in os.walk('.'):
    for f in files:
        if f.endswith('.sh'):
            fix_file(os.path.join(root, f))
