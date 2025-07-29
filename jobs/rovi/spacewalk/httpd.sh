#!/bin/bash
set -euo pipefail

# Count the number of 'httpd' processes excluding the grep command itself
count=$(ps -aef | pgrep -q '[h]ttpd' && ps -aef | pgrep '[h]ttpd' | wc -l || echo 0)

# Exit 0 if at least one httpd process is running, else exit 1
if (( count >= 1 )); then
    exit 0
else
    exit 1
fi
