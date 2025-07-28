#!/usr/bin/env bash
# This script updates all BitBucket repositories by:
# 1. Pruning remote branches
# 2. Pulling latest changes
# 3. Cleaning up local branches
# shellcheck disable=SC2010,SC2155,SC2167

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Icons
REPO_ICON="📦"
BRANCH_ICON="🔖"
SUCCESS_ICON="✅"
ERROR_ICON="❌"
WARNING_ICON="⚠️"
UPDATE_ICON="🔄"
ORG_ICON="🏢"
CLEAN_ICON="🧹"

# Variables
BITBUCKET_DIR="${HOME}/BitBucket/"
ORG_LIST=$(ls -lh "${BITBUCKET_DIR}" | grep drwx | awk '{print $NF}')
CURRENT_DIR=$(pwd)

# Log messages
log_message() {
  local icon=""
  
  # Determine icon based on message content
  if [[ "$1" == *"ERROR"* ]]; then
    icon="${ERROR_ICON} "
  elif [[ "$1" == *"WARNING"* ]]; then
    icon="${WARNING_ICON} "
  elif [[ "$1" == *"Updating"* ]]; then
    icon="${UPDATE_ICON} "
  elif [[ "$1" == *"Cleaning"* ]]; then
    icon="${CLEAN_ICON} "
  elif [[ "$1" == *"Processing organization"* ]]; then
    icon="${ORG_ICON} "
  elif [[ "$1" == *"Starting"* || "$1" == *"completed"* ]]; then
    icon="${SUCCESS_ICON} "
  elif [[ "$1" == *"Found repository"* ]]; then
    icon="${REPO_ICON} "
  else
    icon=""
  fi
  
  echo -e "\n${icon}$1"
}

# Update a git repository
git_update() {
  local repo_name=$1
  local branch_name=$2
  
  log_message "Updating ${repo_name} repo on ${BRANCH_ICON} ${branch_name}"
  
  # Switch to the appropriate branch
  git checkout "${branch_name}" || {
    log_message "ERROR: Failed to checkout branch ${BRANCH_ICON} ${branch_name}"
    return 1
  }
  
  # Prune remote branches
  git remote prune origin
  
  # Pull latest changes
  git pull || {
    log_message "ERROR: Failed to pull latest changes"
    return 1
  }
  
  # Clean up local branches (excluding the current branch)
  log_message "Cleaning up old branches"
  git branch | grep -v "${branch_name}" | awk '{print $NF}' | while read -r local_branch; do
    git branch -D "${local_branch}" || log_message "WARNING: Failed to delete branch ${BRANCH_ICON} ${local_branch}"
  done
  
  return 0
}

# Determine the primary branch for a repository
detect_primary_branch() {
  # Check for common branch names in order of preference
  for branch_name in develop dev main master; do
    if git branch | grep -q "${branch_name}"; then
      echo "${branch_name}"
      return 0
    fi
  done
  
  # If none of the common branches are found, use the current branch
  git branch | awk '{print $NF}' | head -n 1
}

# Get repository name from remote URL
get_repo_name() {
  local git_url
  
  if git config --get remote.origin.url | grep -q "https"; then
    git_url=$(git config --get remote.origin.url | awk -F/ '{print $NF}' | sed -e 's/\.git//')
  else
    git_url=$(git config --get remote.origin.url | awk -F: '{print $NF}' | sed -e 's/\.git//' -e 's/7999\///')
  fi
  
  echo "${git_url}"
}

# Main execution
log_message "Starting BitBucket repositories update"

# Process each organization
for org in ${ORG_LIST}; do
  log_message "Processing organization: ${org}"
  
  # Process each repository in the organization
  find "${BITBUCKET_DIR}/${org}" -type d -maxdepth 1 -mindepth 1 | sort | while read -r repo_dir; do
    # Save current directory to return to it later
    pushd "${repo_dir}" > /dev/null || {
      log_message "ERROR: Cannot access directory ${repo_dir}, skipping"
      continue
    }
    
    # Skip if not a git repository
    if [[ ! -d .git ]]; then
      log_message "Not a git repository: ${repo_dir}, skipping"
      popd > /dev/null
      continue
    fi
    
    repo_name=$(get_repo_name)
    branch_name=$(detect_primary_branch)
    
    log_message "Found repository: ${repo_name}"
    git_update "${repo_name}" "${branch_name}"
    
    # Return to previous directory
    popd > /dev/null
  done
done

log_message "BitBucket repositories update completed"

# Return to the original directory
cd "${CURRENT_DIR}" || exit 1
