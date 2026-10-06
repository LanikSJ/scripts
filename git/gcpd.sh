#!/usr/bin/env bash
# Clean Old Branches and Pull Latest
# This script checks out a primary branch (develop, dev, main, or master),
# pulls the latest changes, and deletes:
#   1. Orphaned local branches whose upstream remote branch has been deleted
#   2. Branches already merged into the primary branch
#   3. Local-only branches (no upstream) whose commits are already in the
#      primary branch (covers squash merges that "git branch --merged" misses)
# shellcheck disable=SC2162

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as errors

# Icons for better visual feedback
REPO_ICON="📦"
BRANCH_ICON="🔖"
SUCCESS_ICON="✅"
ERROR_ICON="❌"
UPDATE_ICON="🔄"
CLEAN_ICON="🧹"

# Get the repository name from remote URL
get_repo_name() {
  local git_url

  if git config --get remote.origin.url | grep -q "https"; then
    git_url=$(git config --get remote.origin.url | awk -F/ '{print $NF}' | sed -e 's/\.git//')
  else
    git_url=$(git config --get remote.origin.url | awk -F: '{print $NF}' | sed -e 's/\.git//' -e 's/7999\///')
  fi

  echo "${git_url}"
}

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$current_branch" == "unknown" ]]; then
  echo "${ERROR_ICON} Error: Not in a git repository or git command failed"
  exit 1
fi

# Determine the primary branch more reliably by checking if branches exist
detect_primary_branch() {
  # Check for common branch names in order of preference
  for branch_name in develop dev main master; do
    if git show-ref --verify --quiet refs/heads/"${branch_name}"; then
      echo "${branch_name}"
      return 0
    fi
  done

  # If none of the common branches are found, default to master
  echo "master"
}

primary_branch=$(detect_primary_branch)
repo_name=$(get_repo_name)

echo "${REPO_ICON} Repository: $repo_name"
echo "${BRANCH_ICON} Current branch: $current_branch"
echo "${BRANCH_ICON} Primary branch: $primary_branch"

# Function to delete orphaned branches (branches whose upstream is gone)
delete_orphaned_branches() {
  # Prune stale remote-tracking references first
  echo "${UPDATE_ICON} Pruning remote-tracking references..."
  git fetch --prune 2>/dev/null || true

  local active_branch
  active_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Find branches whose upstream remote branch has been deleted
  local orphaned_branches
  orphaned_branches=$(git branch -vv | grep ': gone]' | awk '{print $1}' | grep -v "^${primary_branch}$" | grep -v "^${active_branch}$" || true)

  if [[ -z "$orphaned_branches" ]]; then
    echo "${SUCCESS_ICON} No orphaned branches (deleted upstream) to delete."
  else
    echo "${CLEAN_ICON} The following orphaned branches will be deleted:"
    echo "$orphaned_branches"

    # Delete each orphaned branch
    while IFS= read -r branch; do
      if [[ -n "$branch" ]]; then
        echo "${CLEAN_ICON} Deleting orphaned branch: $branch"
        git branch -D "$branch" 2>/dev/null || echo "${ERROR_ICON} Failed to delete branch: $branch"
      fi
    done <<< "$orphaned_branches"
  fi

  # Find branches already merged into the primary branch (safe to delete)
  local merged_branches
  merged_branches=$(git branch --merged "$primary_branch" | awk '{print $1}' | grep -v '^\*$' | grep -v "^${primary_branch}$" | grep -v "^${active_branch}$" || true)

  if [[ -z "$merged_branches" ]]; then
    echo "${SUCCESS_ICON} No merged branches to delete."
  else
    echo "${CLEAN_ICON} The following merged branches will be deleted:"
    echo "$merged_branches"

    while IFS= read -r branch; do
      if [[ -n "$branch" ]]; then
        echo "${CLEAN_ICON} Deleting merged branch: $branch"
        git branch -d "$branch" 2>/dev/null || echo "${ERROR_ICON} Failed to delete branch: $branch"
      fi
    done <<< "$merged_branches"
  fi

  # Clean local-only branches (never pushed, or pushed without -u). These can
  # never show as "gone", so delete them only when every commit already exists
  # in the primary branch (covers squash merges, which --merged misses).
  local local_only_branches branch kept_branches=""
  local_only_branches=$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/ \
    | awk '$2 == "" {print $1}' \
    | grep -v "^${primary_branch}$" \
    | grep -v "^${active_branch}$" || true)

  if [[ -n "$local_only_branches" ]]; then
    while IFS= read -r branch; do
      if [[ -z "$branch" ]]; then
        continue
      fi
      if git cherry "$primary_branch" "$branch" 2>/dev/null | grep -q '^+'; then
        kept_branches+="${branch}"$'\n'
      else
        echo "${CLEAN_ICON} Deleting local-only branch (commits already in ${primary_branch}): $branch"
        git branch -D "$branch" 2>/dev/null || echo "${ERROR_ICON} Failed to delete branch: $branch"
      fi
    done <<< "$local_only_branches"
    kept_branches=${kept_branches%$'\n'}
  fi

  if [[ -n "$kept_branches" ]]; then
    echo "${BRANCH_ICON} Local-only branches kept (unpushed and not yet in ${primary_branch}):"
    echo "$kept_branches"
  fi

  echo "${SUCCESS_ICON} Orphaned branch cleanup completed."
}

# Main logic
if [[ "$current_branch" != "$primary_branch" ]]; then
  echo "${UPDATE_ICON} Switching to $primary_branch branch and pulling latest changes..."
  if git checkout "$primary_branch"; then
    git pull || { echo "${ERROR_ICON} Failed to pull latest changes"; exit 1; }

    # Automatically clean up orphaned branches when switching
    echo "${CLEAN_ICON} Cleaning up orphaned branches..."
    delete_orphaned_branches
  else
    echo "${ERROR_ICON} Failed to checkout $primary_branch branch"
    exit 1
  fi
else
  echo "${UPDATE_ICON} Already on $primary_branch branch. Pulling latest changes..."
  git pull || { echo "${ERROR_ICON} Failed to pull latest changes"; exit 1; }

  # Automatically clean up orphaned branches
  echo "${CLEAN_ICON} Cleaning up orphaned branches..."
  delete_orphaned_branches
fi

echo "${SUCCESS_ICON} Operation completed successfully."