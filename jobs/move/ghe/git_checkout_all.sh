#!/usr/bin/env bash

# Check if the current directory is a Git repository
if [[ -d .git ]]; then
    # Discard all local changes in the working directory
    # Prefer 'git restore .' for Git versions 2.23+
    # Fallback to 'git checkout .' for older versions
    if git help restore >/dev/null 2>&1; then
        echo "Discarding all local changes using 'git restore .'"
        git restore .
    else
        echo "Discarding all local changes using 'git checkout .'"
        git checkout .
    fi
else
    echo "Not a Git repository. No changes to discard."
fi
