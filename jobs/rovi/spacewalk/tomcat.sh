#!/bin/bash
set -euo pipefail

# Search for paths containing 'manager' with 'webapps', excluding 'tmp' and 'cache'
if find / -name '*manager*' 2>/dev/null | grep -q 'webapps' | grep -vqE 'tmp|cache'; then
    exit 5
fi

# Search for paths containing 'manager' with 'catalina' (case-insensitive), excluding 'tmp' and 'cache'
if find / -name '*manager*' 2>/dev/null | grep -i 'catalina' | grep -vqE 'tmp|cache'; then
    exit 5
fi
