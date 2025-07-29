#!/bin/bash
set -euo pipefail

# Count the number of running "java" processes
# pgrep -c returns the count; if no processes, outputs nothing and exits with non-zero
count=$(pgrep -c java || echo 0)

# Exit 0 if at least 2 java processes are running, else exit 1
if (( count >= 2 )); then
    exit 0
else
    exit 1
fi
