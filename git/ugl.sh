#!/usr/bin/env bash
# This script will go through all GitLab repos and update them
# shellcheck disable=SC2010

# Icons
REPO_ICON="📦"
BRANCH_ICON="🔖"
SUCCESS_ICON="✅"
ERROR_ICON="❌"
WARNING_ICON="⚠️"
UPDATE_ICON="🔄"
ORG_ICON="🏢"

# Variables
GITLAB_DIR="$HOME/GitLab/"
ORIGINAL_DIR="$(pwd)"
DEFAULT_BRANCHES=("main" "master" "develop" "dev")

# Function to update a git repository
update_git_repo() {
  local repo_dir="$1"
  local current_branch
  
  # Change to the repository directory
  cd "$repo_dir" || { echo "$ERROR_ICON Failed to change to directory: $repo_dir"; return 1; }
  
  # Check if this is a git repository
  if [[ ! -d .git ]]; then
    echo "$WARNING_ICON Not a git repository: $repo_dir"
    return 0
  fi
  
  # Get repository information
  local repo_name
  repo_name=$(basename "$repo_dir")
  
  # Determine the current branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -z "$current_branch" ]]; then
    echo "$WARNING_ICON Not on any branch in $repo_name"
    return 0
  fi
  
  # Check if current branch is a default branch
  local is_default_branch=false
  for branch in "${DEFAULT_BRANCHES[@]}"; do
    if [[ "$current_branch" == "$branch" ]]; then
      is_default_branch=true
      break
    fi
  done
  
  if [[ "$is_default_branch" == true ]]; then
    echo -e "\n$REPO_ICON Updating $repo_name on $BRANCH_ICON branch $current_branch"
  else
    echo -e "\n$REPO_ICON Updating $repo_name on $BRANCH_ICON branch $current_branch"
  fi
  
  # Prune remote branches and pull updates
  echo "$UPDATE_ICON Pruning remote branches and pulling updates..."
  git remote prune origin
  git pull origin "$current_branch" || echo "$ERROR_ICON Warning: Failed to pull updates for $repo_name"
  
  # Optionally clean up local branches (commented out for safety)
  # Uncomment if you want to delete local branches that don't exist on remote
  # echo "Cleaning up local branches..."
  # git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
  
  return 0
}

# Main function to update all GitLab repositories
update_all_gitlab_repos() {
  echo -e "\n$UPDATE_ICON Updating GitLab Repositories"
  
  # Get list of organization directories
  local orgs=()
  while IFS= read -r org; do
    if [[ -d "$GITLAB_DIR/$org" ]]; then
      orgs+=("$org")
    fi
  done < <(ls -1 "$GITLAB_DIR")
  
  # Process each organization
  for org in "${orgs[@]}"; do
    echo -e "\n$ORG_ICON Processing organization: $org"
    
    # Find all repositories in this organization
    local repos=()
    while IFS= read -r repo; do
      repos+=("$repo")
    done < <(find "$GITLAB_DIR/$org" -mindepth 1 -maxdepth 1 -type d | sort)
    
    # Update each repository
    for repo in "${repos[@]}"; do
      update_git_repo "$repo"
      # Return to the original directory after processing each repo
      cd "$ORIGINAL_DIR" || { echo "$ERROR_ICON Failed to return to original directory"; exit 1; }
    done
  done
  
  echo -e "\n$SUCCESS_ICON All GitLab repositories have been processed."
}

# Run the main function
update_all_gitlab_repos
