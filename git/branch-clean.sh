#!/usr/bin/env bash
# -----------------------------------------------------------------------
# branch-clean.sh - Remove old branches from Homebrew taps
# -----------------------------------------------------------------------
# Usage: ./branch-clean.sh [--dry-run] [--verbose]
#
# Options:
#   --dry-run  Show what would be done without making changes
#   --verbose  Show detailed information during execution
# -----------------------------------------------------------------------

set -e  # Exit immediately if a command exits with a non-zero status

# Default configuration
HOMEBREW_PATH="/opt/homebrew/Library/Taps"
VERBOSE=false
DRY_RUN=false

# Process command line arguments
for arg in "$@"; do
  case $arg in
    --verbose)
      VERBOSE=true
      ;;
    --dry-run)
      DRY_RUN=true
      echo "🔍 DRY RUN MODE: No changes will be made"
      ;;
    --help)
      echo "Usage: $(basename "$0") [--dry-run] [--verbose]"
      echo
      echo "Options:"
      echo "  --dry-run  Show what would be done without making changes"
      echo "  --verbose  Show detailed information during execution"
      echo "  --help     Show this help message"
      exit 0
      ;;
  esac
done

# Log function for verbose output
log() {
  if [[ "$VERBOSE" == true ]]; then
    echo "ℹ️ $1"
  fi
}

# Error handling function
error() {
  echo "❌ ERROR: $1" >&2
  exit 1
}

# Function to check if directory exists
check_directory() {
  if [[ ! -d "$1" ]]; then
    error "Directory does not exist: $1"
  fi
}

# Function to check if we're in a git repository
check_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    error "Not in a git repository: $(pwd)"
  fi
}

# Function to clean branches in a repository
clean_branches() {
  local repo_path="$1"
  local main_branch="$2"
  
  # Navigate to repository
  log "Processing repository: $repo_path"
  check_directory "$repo_path"
  cd "$repo_path" || error "Failed to change directory to $repo_path"
  
  # Check if we're in a git repository
  check_git_repo
  
  # Check if main branch exists
  if ! git show-ref --verify --quiet "refs/heads/$main_branch"; then
    error "Main branch '$main_branch' does not exist in repository: $repo_path"
  fi
  
  # Get list of branches excluding the main branch
  local branches
  branches=$(git branch | grep -v "$main_branch" | tr -d '[:space:]*')
  
  if [[ -z "$branches" ]]; then
    log "No branches to remove in $repo_path"
    return 0
  fi
  
  # Checkout main branch
  if [[ "$DRY_RUN" == false ]]; then
    log "Checking out $main_branch branch"
    git checkout "$main_branch" &>/dev/null || error "Failed to checkout $main_branch branch"
  else
    log "Would checkout $main_branch branch"
  fi
  
  # Remove each branch
  for branch in $branches; do
    if [[ "$DRY_RUN" == false ]]; then
      log "Removing branch: $branch"
      git branch -D "$branch" || error "Failed to delete branch: $branch"
    else
      log "Would remove branch: $branch"
    fi
  done
  
  log "Finished cleaning branches in $repo_path"
}

# Main execution
main() {
  # Homebrew core repositories
  local homebrew_repos=("homebrew-core" "homebrew-cask")
  
  for repo in "${homebrew_repos[@]}"; do
    repo_path="$HOMEBREW_PATH/homebrew/$repo"
    clean_branches "$repo_path" "master"
  done
  
  # LanikSJ tap repository
  clean_branches "$HOMEBREW_PATH/laniksj/homebrew-tap" "main"
  
  echo "✅ Branch cleanup completed successfully"
}

# Run the main function
main
