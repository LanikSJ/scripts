#!/bin/bash
# Optimized zoxide cleanup — pattern or stale removal
set -euo pipefail

# Defaults
pattern=""
stale=false
dry_run=false
verbose=false

# Parse args (fast path: no subcommands, no color setup)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pattern)  pattern="$2"; shift 2 ;;
        --stale)    stale=true; shift ;;
        --dry-run)  dry_run=true; shift ;;
        --verbose|-v) verbose=true; shift ;;
        --help|-h)  cat <<EOF
Usage: ${0##*/} [--pattern PAT|--stale] [--dry-run] [--verbose]

Remove zoxide database entries matching a pattern or with missing directories.
Default pattern: $USER
EOF
            exit 0 ;;
        *)  echo "❓ Unknown: $1" >&2; exit 1 ;;
    esac
done

# Default to pattern mode
[[ -z "$pattern" && "$stale" == false ]] && pattern="$USER"

# Guard
command -v zoxide &>/dev/null || { echo "🚫 Error: zoxide is not installed or not in PATH" >&2; exit 1; }

# Fetch entries once
entries=$(zoxide query --list 2>/dev/null) || entries=""
[[ -z "$entries" ]] && { echo "🔍 No entries in zoxide database"; exit 0; }

# Collect targets
targets=()
if [[ "$stale" == true ]]; then
    echo "🧹 Cleaning up invalid directories from zoxide database..."
    while IFS= read -r dir; do
        [[ -n "$dir" && ! -d "$dir" ]] && targets+=("$dir")
    done <<< "$entries"
else
    # Fast path: grep directly on the stream
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && targets+=("$dir")
    done < <(echo "$entries" | grep "$pattern" 2>/dev/null || true)
fi

[[ ${#targets[@]} -eq 0 ]] && { echo "🔍 No matching entries found in zoxide database"; exit 0; }

# Remove
removed=0
failed=0
for path in "${targets[@]}"; do
    $verbose && echo "🔄 Processing: $path"
    $dry_run && { echo "🗑️  Would remove: $path"; continue; }
    if zoxide remove "$path" 2>/dev/null; then
        echo "✓ Removed: $path"
        ((removed++))
    else
        echo "⚠ Failed to remove: $path" >&2
        ((failed++))
    fi
done

if $dry_run; then
    echo "📊 Would remove ${#targets[@]} entries"
else
    echo "📊 Summary: $removed removed, $failed failed out of ${#targets[@]} total entries"
fi
