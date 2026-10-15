#!/usr/bin/env bash
# 🧹🔄 Update all GitHub repos in a directory, delete old branches, and pull latest

set -euo pipefail

# Icons for components
GIT_ICON="📂"


# Log functions for consistent output
log_info() {
  echo -e "$1"
}

log_success() {
  echo -e "$1"
}

log_warning() {
  echo -e "⚠️ WARNING: $1"
}

log_error() {
  echo -e "❌ ERROR: $1"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 📁 Variables
GITHUB="${HOME}/GitHub/LanikSJ"
repolist=()

# 🗂️ Build repo list
for dir in "$GITHUB"/*; do
  [[ -d "$dir/.git" ]] && repolist+=("$(basename "$dir")")
done

# 🛠️ Git update function (shared with umac.zsh)
git_update() {
  local repo="$1"
  local branch="$2"

  log_info "\n🔄 Updating $repo on branch $branch"

  git checkout "$branch" || {
    log_warning "Failed to checkout $branch for $repo — continuing with cleanup"
  }

  git pull || {
    log_warning "Failed to pull updates for $repo — continuing with cleanup"
  }

  # Prune remote tracking branches that no longer exist on remote
  log_info "🧹 Pruning remote tracking branches for $repo"
  git remote prune origin || log_warning "Failed to prune remote for $repo"

  # Delete all local branches except the primary/default branch
  log_info "🗑️ Deleting non-default local branches for $repo"
  for b in $(git branch | grep -v " $branch\$" | grep -v "^\*" | awk '{print $NF}'); do
    log_info "  🗑️ Deleting local branch: $b"
    git branch -D "$b" || log_warning "Failed to delete local branch $b"
  done
}

log_info "🚀 Starting GitHub repository update process"

log_info "\n${GIT_ICON} Updating LanikSJ repositories"

# Check if git is available
if ! command_exists git; then
  log_error "Git command not found. Please install git."
  exit 1
fi

# Check if GitHub directory exists
if [[ ! -d "$GITHUB" ]]; then
  log_warning "LanikSJ directory not found: $GITHUB. Skipping."
  exit 0
fi

# Check if there are any repositories to update
if [[ ${#repolist[@]} -eq 0 ]]; then
  log_warning "No git repositories found in $GITHUB"
  exit 0
fi

log_info "Found ${#repolist[@]} repositories to update in LanikSJ"

# 🧵 Parallel update (default: one job per CPU core, override with UGH_JOBS) - bash compatible version
JOBS="${UGH_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
pids=()
for repo in "${repolist[@]}"; do
  (
    # Save current directory to return to it later
    current_dir=$(pwd)
    
    cd "$GITHUB/$repo" || {
      log_error "Could not change to repository: $GITHUB/$repo"
      exit 1
    }
    
    # Detect primary branch
    if git show-ref --verify --quiet refs/heads/develop; then
      branch="develop"
    elif git show-ref --verify --quiet refs/heads/dev; then
      branch="dev"
    elif git show-ref --verify --quiet refs/heads/main; then
      branch="main"
    else
      branch="master"
    fi
    
    git_update "$repo" "$branch"
    log_success "✅ $repo updated and cleaned"
    
    # Return to original directory
    cd "$current_dir" || log_warning "Could not return to original directory"
  ) &
  pids+=($!)
  # Limit parallel jobs - bash compatible version
  if (( ${#pids[@]} >= JOBS )); then
    # Use wait -n for bash (supported in bash 4.3+)
    if wait -n 2>/dev/null; then
      # Remove finished jobs from array (bash compatible)
      new_pids=()
      for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
          new_pids+=("$pid")
        fi
      done
      pids=("${new_pids[@]}")
    else
      # Fallback for older bash versions
      wait
      pids=()
    fi
  fi
done

# Wait for all jobs to finish
wait

echo -e "\n🎉 All repositories updated!"
