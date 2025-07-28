#!/usr/bin/env bash
# Clean Old Branches and Pull Latest
# This script checks out a primary branch (develop, dev, main, or master),
# pulls the latest changes, and optionally deletes other local branches.
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

# Function to delete branches without confirmation
delete_other_branches() {
  # List branches excluding the primary branch
  branches_to_delete=$(git branch | grep -v "$primary_branch" | tr -d ' *')
  
  if [[ -z "$branches_to_delete" ]]; then
    echo "${SUCCESS_ICON} No other branches to delete."
    return 0
  fi
  
  echo "${CLEAN_ICON} The following branches will be deleted:"
  echo "$branches_to_delete"
  
  # Delete each branch
  echo "$branches_to_delete" | while read -r branch; do
    if [[ -n "$branch" ]]; then
      echo "${CLEAN_ICON} Deleting branch: $branch"
      git branch -D "$branch" || echo "${ERROR_ICON} Failed to delete branch: $branch"
    fi
  done
  
  echo "${SUCCESS_ICON} Branch cleanup completed."
}

# Main logic
if [[ "$current_branch" != "$primary_branch" ]]; then
  echo "${UPDATE_ICON} Switching to $primary_branch branch and pulling latest changes..."
  if git checkout "$primary_branch"; then
    git pull || { echo "${ERROR_ICON} Failed to pull latest changes"; exit 1; }
    
    # Automatically clean up branches when switching
    echo "${CLEAN_ICON} Cleaning up old branches..."
    delete_other_branches
  else
    echo "${ERROR_ICON} Failed to checkout $primary_branch branch"
    exit 1
  fi
else
  echo "${UPDATE_ICON} Already on $primary_branch branch. Pulling latest changes..."
  git pull || { echo "${ERROR_ICON} Failed to pull latest changes"; exit 1; }
  
  # Automatically clean up branches
  echo "${CLEAN_ICON} Cleaning up old branches..."
  delete_other_branches
fi

echo "${SUCCESS_ICON} Operation completed successfully."
