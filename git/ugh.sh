#!/usr/bin/env bash
# ugh-improved.sh - Update GitHub Repositories
# This script updates all GitHub repositories in a specified directory

set -o errexit   # Exit on error
set -o nounset   # Error on unset variables
set -o pipefail  # Pipe fails on any command failure

# Default configuration
GITHUB_DIR="${HOME}/GitHub/LanikSJ"
LOG_FILE="${HOME}/github-update.log"
PARALLEL=false
MAX_JOBS=4
VERBOSE=false
STASH_CHANGES=true
FETCH_ONLY=false
PRUNE_REMOTE=true

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "${timestamp} $*" | tee -a "${LOG_FILE}"
}

log_info() {
  log "${BLUE}INFO:${NC} $*"
}

log_success() {
  log "${GREEN}SUCCESS:${NC} $*"
}

log_warning() {
  log "${YELLOW}WARNING:${NC} $*"
}

log_error() {
  log "${RED}ERROR:${NC} $*"
}

show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Update all GitHub repositories in a specified directory.

Options:
  -d, --directory DIR    Specify the GitHub directory (default: ${GITHUB_DIR})
  -p, --parallel         Update repositories in parallel
  -j, --jobs NUM         Maximum number of parallel jobs (default: ${MAX_JOBS})
  -f, --fetch-only       Only fetch updates, don't checkout or merge
  -n, --no-stash         Don't stash changes before updating
  --no-prune             Don't prune remote branches
  -v, --verbose          Show verbose output
  -h, --help             Show this help message and exit

Examples:
  $(basename "$0")                      # Update all repos in default directory
  $(basename "$0") -d ~/code            # Update all repos in ~/code
  $(basename "$0") -p -j 8              # Update in parallel with 8 jobs
  $(basename "$0") -f                   # Only fetch updates, don't merge

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -d|--directory)
        GITHUB_DIR="$2"
        shift 2
        ;;
      -p|--parallel)
        PARALLEL=true
        shift
        ;;
      -j|--jobs)
        MAX_JOBS="$2"
        shift 2
        ;;
      -f|--fetch-only)
        FETCH_ONLY=true
        shift
        ;;
      -n|--no-stash)
        STASH_CHANGES=false
        shift
        ;;
      --no-prune)
        PRUNE_REMOTE=false
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done

  # Validate arguments
  if [[ ! -d "${GITHUB_DIR}" ]]; then
    log_error "Directory does not exist: ${GITHUB_DIR}"
    exit 1
  fi

  # Remove trailing slash if present
  GITHUB_DIR="${GITHUB_DIR%/}"
}

# Get the primary branch of a repository
get_primary_branch() {
  local repo_path="$1"
  local current_branch
  
  # Get current branch
  if ! current_branch=$(git -C "${repo_path}" rev-parse --abbrev-ref HEAD 2>/dev/null); then
    echo ""
    return 1
  fi
  
  # Check for common primary branch names in order of preference
  for branch in "develop" "dev" "main" "master"; do
    if git -C "${repo_path}" show-ref --verify --quiet "refs/heads/${branch}"; then
      echo "${branch}"
      return 0
    fi
  done
  
  # Fall back to current branch
  echo "${current_branch}"
  return 0
}

# Update a single repository
update_repo() {
  local repo="$1"
  local repo_path="${GITHUB_DIR}/${repo}"
  local stash_created=false
  local result=0
  
  # Skip if not a directory
  if [[ ! -d "${repo_path}" ]]; then
    log_warning "Not a directory: ${repo_path}, skipping..."
    return 1
  fi
  
  # Skip if not a git repository
  if [[ ! -d "${repo_path}/.git" ]]; then
    log_warning "${repo} is not a git repository, skipping..."
    return 1
  fi
  
  log_info "Processing ${repo}"
  
  # Fetch updates from remote
  if ${VERBOSE}; then
    log_info "Fetching updates for ${repo}..."
  fi
  
  local fetch_args=("--quiet")
  if ${PRUNE_REMOTE}; then
    fetch_args+=("--prune")
  fi
  
  if ! git -C "${repo_path}" fetch "${fetch_args[@]}" origin; then
    log_error "Failed to fetch updates for ${repo}"
    return 1
  fi
  
  # If fetch-only mode, we're done with this repo
  if ${FETCH_ONLY}; then
    log_success "Fetched updates for ${repo}"
    return 0
  fi
  
  # Get primary branch
  local branch
  if ! branch=$(get_primary_branch "${repo_path}"); then
    log_error "Failed to determine branch for ${repo}, skipping..."
    return 1
  fi
  
  if ${VERBOSE}; then
    log_info "Using branch: ${branch} for ${repo}"
  fi
  
  # Stash any uncommitted changes if requested
  if ${STASH_CHANGES}; then
    if [[ -n $(git -C "${repo_path}" status --porcelain) ]]; then
      if ${VERBOSE}; then
        log_info "Stashing uncommitted changes in ${repo}..."
      fi
      if git -C "${repo_path}" stash save "Auto-stash before updating ${branch}"; then
        stash_created=true
      else
        log_warning "Failed to stash changes in ${repo}, continuing anyway..."
      fi
    fi
  fi
  
  # Checkout the primary branch
  if ! git -C "${repo_path}" checkout --quiet "${branch}"; then
    log_error "Failed to checkout ${branch} in ${repo}"
    result=1
  else
    # Pull updates
    if ${VERBOSE}; then
      log_info "Pulling updates for ${repo} on ${branch}..."
    fi
    
    if ! git -C "${repo_path}" pull --quiet --ff-only origin "${branch}"; then
      log_error "Failed to pull updates for ${repo} on ${branch}"
      result=1
    else
      log_success "Updated ${repo} on ${branch}"
    fi
  fi
  
  # Pop stashed changes if we created a stash
  if ${stash_created}; then
    if ${VERBOSE}; then
      log_info "Restoring stashed changes in ${repo}..."
    fi
    if ! git -C "${repo_path}" stash pop --quiet; then
      log_warning "Failed to restore stashed changes in ${repo}. Changes remain in stash."
    elif ${VERBOSE}; then
      log_info "Restored stashed changes in ${repo}"
    fi
  fi
  
  return ${result}
}

# Main function
main() {
  local start_time
  local end_time
  local total_time
  local success_count=0
  local fail_count=0
  local total_repos=0
  
  # Parse command line arguments
  parse_args "$@"
  
  # Initialize log file
  : > "${LOG_FILE}"
  
  log_info "Starting GitHub repository updates in ${GITHUB_DIR}"
  start_time=$(date +%s)
  
  # Get list of repositories (directories only)
  local repos=()
  while IFS= read -r -d '' dir; do
    # Get just the directory name, not the full path
    repo=$(basename "${dir}")
    repos+=("${repo}")
  done < <(find "${GITHUB_DIR}" -mindepth 1 -maxdepth 1 -type d -print0)
  
  total_repos=${#repos[@]}
  log_info "Found ${total_repos} potential repositories"
  
  if ${PARALLEL}; then
    # Update repositories in parallel
    log_info "Updating repositories in parallel (max ${MAX_JOBS} jobs)"
    
    # Use a temporary file as a semaphore for parallel jobs
    local semaphore="/tmp/github-update-semaphore-$$"
    # Create temporary files to track success/failure counts from background processes
    local success_file="/tmp/github-update-success-$$"
    local fail_file="/tmp/github-update-fail-$$"
    
    # Initialize counter files
    echo 0 > "${success_file}"
    echo 0 > "${fail_file}"
    
    mkfifo "${semaphore}"
    
    # Start background process to manage the semaphore
    exec 3<>"${semaphore}"
    rm "${semaphore}"
    
    # Initialize the semaphore with MAX_JOBS tokens
    for ((i=1; i<=MAX_JOBS; i++)); do
      echo >&3
    done
    
    for repo in "${repos[@]}"; do
      # Wait for a token from the semaphore
      read -r -u 3
      
      # Run the update in the background
      {
        if update_repo "${repo}"; then
          # Atomically increment success count in the file
          local current_success
          current_success=$(cat "${success_file}")
          echo $((current_success + 1)) > "${success_file}"
        else
          # Atomically increment fail count in the file
          local current_fail
          current_fail=$(cat "${fail_file}")
          echo $((current_fail + 1)) > "${fail_file}"
        fi
        
        # Return the token to the semaphore
        echo >&3
      } &
    done
    
    # Wait for all background jobs to complete
    wait
    
    # Read final counts from files
    success_count=$(cat "${success_file}")
    fail_count=$(cat "${fail_file}")
    
    # Clean up temporary files
    rm -f "${success_file}" "${fail_file}"
    
    # Close the semaphore
    exec 3>&-
  else
    # Update repositories sequentially
    log_info "Updating repositories sequentially"
    
    for repo in "${repos[@]}"; do
      if update_repo "${repo}"; then
        ((success_count++))
      else
        ((fail_count++))
      fi
    done
  fi
  
  # Calculate elapsed time
  end_time=$(date +%s)
  total_time=$((end_time - start_time))
  
  # Print summary
  log_info "Update completed in ${total_time} seconds"
  log_info "Repositories processed: ${total_repos}"
  log_success "Successfully updated: ${success_count}"
  
  if ((fail_count > 0)); then
    log_warning "Failed to update: ${fail_count}"
    log_info "Check ${LOG_FILE} for details"
  fi
  
  if ((success_count == total_repos)); then
    log_success "All repositories updated successfully!"
    return 0
  else
    log_warning "Some repositories were not updated successfully."
    return 1
  fi
}

# Run the main function with all arguments
main "$@"
