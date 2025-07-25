#!/usr/bin/env bash
# Clean Old Branches and Pull Latest
# This script checks out a primary branch (develop, dev, main, or master),
# pulls the latest changes, and optionally deletes other local branches.

set -e  # Exit immediately if a command exits with a non-zero status

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$current_branch" == "unknown" ]]; then
  echo "Error: Not in a git repository or git command failed"
  exit 1
fi

# Determine the primary branch more reliably by checking if branches exist
if git show-ref --verify --quiet refs/heads/develop; then
  primary_branch="develop"
elif git show-ref --verify --quiet refs/heads/dev; then
  primary_branch="dev"
elif git show-ref --verify --quiet refs/heads/main; then
  primary_branch="main"
else
  primary_branch="master"
fi

echo "Current branch: $current_branch"
echo "Primary branch: $primary_branch"

# Function to delete branches with confirmation
delete_other_branches() {
  # List branches excluding the primary branch
  branches_to_delete=$(git branch | grep -v "$primary_branch" | tr -d ' *')
  
  if [[ -z "$branches_to_delete" ]]; then
    echo "No other branches to delete."
    return 0
  fi
  
  echo "The following branches will be deleted:"
  echo "$branches_to_delete"
  
  # Check if FORCE_DELETE environment variable is set
  if [[ -z "$FORCE_DELETE" ]]; then
    read -r -p "Do you want to continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Branch deletion cancelled."
      return 1
    fi
  else
    echo "FORCE_DELETE is set. Proceeding with branch deletion without confirmation."
  fi
  
  # Delete each branch
  echo "$branches_to_delete" | while read -r branch; do
    if [[ -n "$branch" ]]; then
      echo "Deleting branch: $branch"
      git branch -D "$branch" || echo "Failed to delete branch: $branch"
    fi
  done
}

# Main logic
if [[ "$current_branch" != "$primary_branch" ]]; then
  echo "Switching to $primary_branch branch and pulling latest changes..."
  if git checkout "$primary_branch"; then
    git pull || { echo "Error: Failed to pull latest changes"; exit 1; }
    delete_other_branches
  else
    echo "Error: Failed to checkout $primary_branch branch"
    exit 1
  fi
else
  echo "Already on $primary_branch branch. Pulling latest changes..."
  git pull || { echo "Error: Failed to pull latest changes"; exit 1; }
  
  # Ask if user wants to delete other branches
  read -r -p "Do you want to delete other branches? (y/N): " delete_confirm
  if [[ "$delete_confirm" == "y" || "$delete_confirm" == "Y" ]]; then
    delete_other_branches
  fi
fi

echo "Operation completed successfully."
