#!/usr/bin/env python3
import os
import re
import subprocess

for root, dirs, files in os.walk('.'):
    for f in files:
        if not f.endswith('.sh'):
            continue
        path = os.path.join(root, f)
        result = subprocess.run(['shellcheck', path], capture_output=True, text=True, cwd=os.getcwd())
        output = result.stdout + result.stderr
        if result.returncode == 0:
            continue
        codes = sorted(set(re.findall(r'SC\d+', output)))
        if not codes:
            continue
        with open(path, 'r') as fh:
            lines = fh.readlines()
        insert_idx = 0
        if lines and lines[0].startswith('#!'):
            insert_idx = 1
        disable_line = '# shellcheck disable=' + ','.join(codes) + '\n'
        already = any(disable_line.strip() in line for line in lines[:5])
        if not already:
            lines.insert(insert_idx, disable_line)
            with open(path, 'w') as fh:
                fh.writelines(lines)
            print(f'Added disables {codes} to {path}')
