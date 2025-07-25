#!/usr/bin/env bash
# This script performs cleanup operations on Git repositories
# It removes unreferenced objects and optimizes local repositories

set -e  # Exit immediately if a command exits with a non-zero status

# Function to clean a Git repository
cleanup_repo() {
  local repo_path="$1"
  
  # Check if directory exists
  if [[ ! -d "$repo_path" ]]; then
    echo "Error: Directory $repo_path does not exist"
    return 1
  fi
  
  # Navigate to the repository
  cd "$repo_path" || return 1
  
  # Check if this is a Git repository
  if [[ ! -d .git ]] && ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Skipping $repo_path: Not a Git repository"
    return 0
  fi
  
  # Get current repository URL
  local git_url
  git_url=$(git config --get remote.origin.url)
  
  # Skip if no remote URL is configured
  if [[ -z "$git_url" ]]; then
    echo "Skipping $repo_path: No remote origin configured"
    return 0
  fi
  
  # Extract repository name from URL (supports both SSH and HTTPS formats)
  local repo_name
  if [[ "$git_url" == *"@"* ]]; then
    # SSH format: git@github.com:username/repo.git
    repo_name=$(echo "$git_url" | sed -E 's/.*:(.+)\.git$/\1/')
  else
    # HTTPS format: https://github.com/username/repo.git
    repo_name=$(echo "$git_url" | sed -E 's/.*github\.com\/(.+)\.git$/\1/')
  fi
  
  echo -e "\n===== Cleaning repository: $repo_name ====="
  
  # Perform Git cleanup operations
  echo "Expiring reflog entries..."
  git reflog expire --expire=now --all
  
  echo "Running garbage collection..."
  git gc --prune=now --aggressive
  
  echo "Cleanup completed for $repo_name"
}

# Process repositories in LanikSJ directory
echo "Processing repositories in ~/GitHub/LanikSJ..."
find ~/GitHub/LanikSJ -maxdepth 1 -mindepth 1 -type d | while read -r repo; do
  cleanup_repo "$repo"
done

# Process repositories in Mac directory
echo "Processing repositories in ~/GitHub/Mac..."
find ~/GitHub/Mac -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while read -r repo; do
  cleanup_repo "$repo"
done

echo -e "\nAll repositories have been processed."
