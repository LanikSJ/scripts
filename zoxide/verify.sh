#!/bin/bash

# Zoxide verification script - removes invalid entries from zoxide database
# Removes entries where the referenced directory no longer exists

# Check if zoxide is available
if ! command -v zoxide >/dev/null 2>&1; then
    echo "❌ Error: zoxide command not found. Please install zoxide first." >&2
    exit 1
fi

# Counters for tracking results (using file for inter-process communication)
checked_file=$(mktemp)
removed_file=$(mktemp)
error_file=$(mktemp)
echo 0 > "$checked_file"
echo 0 > "$removed_file"
echo 0 > "$error_file"

echo "🔍 Starting zoxide database verification..."
echo

# Process each path in zoxide database
zoxide query --list | while read -r path; do
    # Update checked count
    checked_count=$(cat "$checked_file")
    ((checked_count++))
    echo $checked_count > "$checked_file"

    # Skip empty lines (though zoxide shouldn't output them)
    [[ -z "$path" ]] && continue

    # Check if path exists and is a directory
    if [[ -d "$path" ]]; then
        # Directory exists, keep it
        echo "✓ Valid: $path"
    else
        # Directory doesn't exist, remove from zoxide
        if zoxide remove "$path" >/dev/null 2>&1; then
            echo "🗑️  Removed: $path"
            # Update removed count
            removed_count=$(cat "$removed_file")
            ((removed_count++))
            echo $removed_count > "$removed_file"
        else
            echo "⚠️  Failed to remove: $path"
            # Update error count
            error_count=$(cat "$error_file")
            ((error_count++))
            echo $error_count > "$error_file"
        fi
    fi
done

# Read final counts
checked_count=$(cat "$checked_file")
removed_count=$(cat "$removed_file")
error_count=$(cat "$error_file")

# Clean up temporary files
rm "$checked_file" "$removed_file" "$error_file"

echo
echo "📊 Verification complete:"
echo "   Checked: $checked_count entries"
echo "   Removed: $removed_count invalid entries"
if [[ $error_count -gt 0 ]]; then
    echo "   🚫 Errors: $error_count removal failures"
fi

if [[ $removed_count -eq 0 ]]; then
    echo "✅ No invalid entries found - zoxide database is clean!"
else
    echo "🧹 Cleaned up $removed_count invalid entries from zoxide database."
fi
