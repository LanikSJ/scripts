#!/bin/bash

# Suppress permission denied errors for cleaner output
# Using -iname to ignore case when matching "manager"

# Check if any path contains "manager" (case-insensitive) and "webapps" (case-sensitive)
if find / -iname '*manager*' -path '*webapps*' -print -quit 2>/dev/null | grep -q .; then
    exit 5
fi

# Check if any path contains "manager" (case-insensitive) and "catalina" (case-insensitive)
if find / -iname '*manager*' -ipath '*catalina*' -print -quit 2>/dev/null | grep -q .; then
    exit 5
fi
