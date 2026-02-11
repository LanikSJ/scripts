#!/bin/bash

set -euo pipefail  # Exit on error, treat undefined vars as errors, fail if any piped command fails

# Check if zoxide is available
if ! command -v zoxide >/dev/null 2>&1; then
    echo "🚫 Error: zoxide is not installed or not in PATH" >&2
    exit 1
fi

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [--dry-run] [--verbose|-v] [--pattern PATTERN]

Clean zoxide database entries matching a pattern.

Options:
    --dry-run      Show what would be removed without actually removing
    --verbose, -v  Show detailed output
    --pattern      Specify custom grep pattern (default: ierenstein)
    --help, -h     Show this help message

Examples:
    $0                              # Clean entries containing 'ierenstein'
    $0 --pattern 'work'             # Clean entries containing 'work'
    $0 --dry-run --verbose          # Show what would be removed verbosely
EOF
}

# Default values
DRY_RUN=false
VERBOSE=false
PATTERN="ierenstein"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "❓ Error: Unknown option '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Get list of paths in a more robust way
# Note: We don't check exit code here because grep returns 1 when no matches found
paths=$(zoxide query --list | grep "$PATTERN" 2>/dev/null || true)

# If no paths found, exit early
if [[ -z "$paths" ]]; then
    echo "🔍 No matching entries found in zoxide database"
    exit 0
fi

# Counters for summary
removed=0
failed=0

# Process each path
while IFS= read -r path; do
    if [[ -z "$path" ]]; then
        continue
    fi

    if $VERBOSE; then
        echo "🔄 Processing: $path"
    fi

    if $DRY_RUN; then
        echo "🗑️  Would remove: $path"
    else
        # Suppress stderr unless verbose
        cmd="zoxide remove '$path'"
        if [ "$VERBOSE" = "true" ]; then
            cmd="$cmd 2>&1"
        else
            cmd="$cmd 2>/dev/null"
        fi
        if eval "$cmd"; then
            echo "✓ Removed: $path"
            removed=$((removed + 1))
        else
            echo "⚠ Failed to remove: $path" >&2
            failed=$((failed + 1))
        fi
    fi
done <<< "$paths"

# Summary (only if not dry run)
if ! $DRY_RUN; then
    total=$((removed + failed))
    echo "📊 Summary: $removed removed, $failed failed out of $total total entries"
fi
