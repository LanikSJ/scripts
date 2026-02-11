#!/bin/bash
# zoxide cleanup script - removes invalid directories from the database

set -e

echo "🧹 Cleaning up invalid directories from zoxide database..."

# Get all entries from zoxide and remove non-existent directories
removed=0
while IFS= read -r dir; do
    if [ ! -d "$dir" ]; then
        echo "❌ Removing: $dir"
        zoxide remove "$dir" 2>/dev/null || true
        removed=$((removed + 1))
    fi
done < <(zoxide query --list)

echo "✨ Cleanup complete! Removed $removed invalid directories."
