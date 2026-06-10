#!/bin/bash
# Script to update AGENTS.md files across all LanikSJ projects by copying the central AGENTS.md

set -e

echo "🔄 Updating AGENTS.md across all LanikSJ projects..."

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Assume the central AGENTS.md is at the repository root (two levels up from this script)
ROOT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$SCRIPT_DIR")")"
MASTER_AGENTS="$ROOT_DIR/AGENTS.md"

if [[ ! -f "$MASTER_AGENTS" ]]; then
  echo "⚠️ Master AGENTS.md not found at $MASTER_AGENTS"
  exit 1
fi

cd "$SCRIPT_DIR"

# Find all project directories that contain an AGENTS.md file (excluding .github directories)
for project_dir in $(find . -name "AGENTS.md" -type f | sed 's|/AGENTS.md||' | grep -v "\.github$" | sort); do
  if [[ -d "$project_dir/.github" ]]; then
    echo "Processing: $project_dir"
    cp "$MASTER_AGENTS" "$project_dir/AGENTS.md"
    echo "✅ Updated $project_dir/AGENTS.md"
  else
    echo "⚠️ Skipping $project_dir (no .github folder)"
  fi
done

echo "🎉 All AGENTS.md files updated successfully!"
