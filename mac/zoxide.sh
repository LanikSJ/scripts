#!/bin/bash

# Enhanced zoxide importer from enhancd log
# Improves the original script with error handling, configurability, and better practices

# Configuration: Allow override via ENHANCD_LOG environment variable
LOG_FILE="${ENHANCD_LOG:-${HOME}/.enhancd/enhancd.log}"

# Check if zoxide is available
if ! command -v zoxide >/dev/null 2>&1; then
    echo "❌ Error: zoxide command not found. Please install zoxide first." >&2
    exit 1
fi

# Check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "❌ Error: Log file not found: $LOG_FILE" >&2
    echo "📝 Please verify the path or set ENHANCD_LOG environment variable." >&2
    exit 1
fi

# Check if log file is readable
if [[ ! -r "$LOG_FILE" ]]; then
    echo "❌ Error: Cannot read log file: $LOG_FILE" >&2
    exit 1
fi

# Counter for tracking added directories
added_count=0

# Improved loop with better line handling and verbosity
while IFS= read -r line; do
    # Skip empty lines and lines starting with #
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Remove leading/trailing whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if the path exists and is a directory
    if [[ -d "$line" ]]; then
        if zoxide add "$line" >/dev/null 2>&1; then
            ((added_count++))
            # Uncomment for verbose output:
            # echo "Added to zoxide: $line"
        else
            echo "⚠️ Warning: Failed to add to zoxide: $line" >&2
        fi
    else
        echo "⚠️ Warning: Skipping invalid directory: $line" >&2
    fi
done < "$LOG_FILE"

# Summary output
echo "✅ Successfully added $added_count directories to zoxide from $LOG_FILE"
