#!/usr/bin/env bash
# Get All Branches in Given Repo

# Set -euo pipefail for robust error handling.
set -euo pipefail

# Check if the current directory is a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not a Git repository. Please run this script inside a Git repository."
  exit 1
fi

echo "🔍 Fetching all remote branches..."
git fetch --all --prune

# Get all remote branches, excluding HEAD and master, and iterate
git for-each-ref --format='%(refname:short)' refs/remotes/ | \
grep -v '/HEAD$' | \
grep -v '/master$' | \
while IFS= read -r remote_branch; do
  # Extract the local branch name from the remote branch (e.g., origin/feature -> feature)
  local_branch=$(echo "$remote_branch" | sed 's/^[a-zA-Z0-9_-]\+\///')

  if git show-ref --verify --quiet "refs/heads/$local_branch"; then
    echo "ℹ️ Local branch '$local_branch' already exists. Skipping '$remote_branch'."
  else
    echo "➡️ Checking out and tracking '$remote_branch' as '$local_branch'..."
    if git checkout --track "$remote_branch"; then
      echo "✅ Successfully checked out '$local_branch'."
    else
      echo "❌ Error: Failed to checkout '$remote_branch'."
      # Optionally, you can exit here or continue with other branches
      # exit 1
    fi
  fi
done

echo "✅ All specified remote branches processed."
