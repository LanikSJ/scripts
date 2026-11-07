#!/usr/bin/env bash
# 🧹🔄 Update all GitHub repos in a directory, delete old branches, and pull latest

set -euo pipefail

# Icons for components
GIT_ICON="📂"

# ANSI colors for consistent, colorful output
COLOR_RESET=$'\033[0m'
COLOR_BOLD=$'\033[1m'
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_CYAN=$'\033[0;36m'

# Log functions for consistent output
log_info() {
  echo -e "${COLOR_CYAN}${COLOR_BOLD}$1${COLOR_RESET}"
}

log_success() {
  echo -e "${COLOR_GREEN}${COLOR_BOLD}$1${COLOR_RESET}"
}

log_warning() {
  echo -e "${COLOR_YELLOW}${COLOR_BOLD}⚠️ WARNING:${COLOR_RESET} ${COLOR_YELLOW}$1${COLOR_RESET}"
}

log_error() {
  echo -e "${COLOR_RED}${COLOR_BOLD}❌ ERROR:${COLOR_RESET} ${COLOR_RED}$1${COLOR_RESET}"
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

# 📦 Flush a finished repo's buffered output as one atomic block (shared with umac.zsh)
flush_repo_log() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cat "$file"
    rm -f "$file"
  fi
}

# 🛠️ Git update function (shared with umac.zsh)
git_update() {
  local repo="$1"
  local branch="$2"

  log_info "\n🔄 Updating $repo on branch $branch"

  git checkout "$branch" || {
    log_warning "Failed to checkout $branch for $repo — continuing with cleanup"
  }

  # Pull updates, capturing output so we can filter git's own
  # "no such ref was fetched" warning which appears when the remote
  # default branch was renamed/deleted (e.g. master → main on GitHub)
  if ! pull_output=$(LC_ALL=C git pull 2>&1); then
    # Display git pull output, excluding only the "no such ref was fetched"
    # message that is deliberately replaced by the targeted warning below
    local filtered_output="" filter_status
    if filtered_output=$(printf '%s\n' "$pull_output" | grep -v -e 'no such ref was fetched' -e "Your configuration specifies to merge with the ref"); then
      :
    else
      filter_status=$?
      if ((filter_status > 1)); then
        return "$filter_status"
      fi
      filtered_output=""
    fi
    if [[ -n "$filtered_output" ]]; then
      printf '%s\n' "$filtered_output"
    fi
    if [[ "$pull_output" == *"no such ref was fetched"* ]]; then
      # Read the branch's configured upstream from git config
      # (branch.<name>.remote + branch.<name>.merge) without resolving the
      # upstream ref, so the configured value is preserved even when its
      # tracking ref has been pruned.
      local current_branch remote merge_ref configured_upstream
      current_branch=$(git branch --show-current 2>/dev/null)
      remote=$(git config "branch.${current_branch}.remote" 2>/dev/null) || remote=""
      merge_ref=$(git config "branch.${current_branch}.merge" 2>/dev/null) || merge_ref=""
      if [[ -n "$remote" && -n "$merge_ref" ]]; then
        configured_upstream="${remote}/${merge_ref#refs/heads/}"
      else
        configured_upstream="<unknown>"
      fi
      log_warning "Configured upstream '$configured_upstream' has no matching ref for $repo — skipping pull"
    else
      log_warning "Failed to pull updates for $repo — continuing with cleanup"
    fi
  else
    if [[ -n "$pull_output" ]]; then
      printf '%s\n' "$(colorize_diff_stats "$pull_output")"
    fi
  fi

  # Prune remote tracking branches that no longer exist on remote
  log_info "🧹 Pruning remote tracking branches for $repo"
  git remote prune origin || log_warning "Failed to prune remote for $repo"

  # Delete all local branches except the primary/default branch
  log_info "🗑️ Deleting non-default local branches for $repo"
  git branch | grep -v " $branch\$" | grep -v "^\*" | awk '{print $NF}' | while IFS= read -r b; do
    log_info "  🗑️ Deleting local branch: $b"
    git branch -D "$b" || log_warning "Failed to delete local branch $b"
  done || true
}

# 🎨 Colorize diff stats from git pull output
# Handles lines like:
#   |  4 ++--     → + in green, - in red (per-character)
#   |  12 ++++++------ → + green, - red
#   |  2 +-       → + green, - red
#   |  5 ++++     → all green
#   |  3 -----    → all red
colorize_diff_stats() {
  local input="$1"
  local line prefix sign_pattern colored_sign char i

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Match lines like "|  4 ++--" or "|  12 ++++++------"
    if [[ "$line" =~ (\|[[:space:]]+[0-9]+[[:space:]])([+-]+) ]]; then
      prefix="${BASH_REMATCH[1]}"
      sign_pattern="${BASH_REMATCH[2]}"

      # Build colored sign string: + → green, - → red (per-character)
      colored_sign=""
      for ((i = 0; i < ${#sign_pattern}; i++)); do
        char="${sign_pattern:$i:1}"
        if [[ "$char" == "+" ]]; then
          colored_sign+="${COLOR_GREEN}+${COLOR_RESET}"
        elif [[ "$char" == "-" ]]; then
          colored_sign+="${COLOR_RED}-${COLOR_RESET}"
        else
          colored_sign+="$char"
        fi
      done

      line="${line/${prefix}${sign_pattern}/${prefix}${colored_sign}}"
    fi
    printf '%s\n' "$line"
  done <<<"$input"
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

# 📦 Buffer each repo's output so parallel jobs don't interleave on the terminal
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

# 🧵 Parallel update (default: one job per CPU core, override with UGH_JOBS) - bash compatible version
JOBS="${UGH_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
job_logs=()
for repo in "${repolist[@]}"; do
  repo_log="$LOG_DIR/$repo.log"
  (
    # Save current directory to return to it later
    current_dir=$PWD

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
  ) >"$repo_log" 2>&1 &
  job_logs+=("$!|$repo_log")
  # Limit parallel jobs - bash compatible version
  if ((${#job_logs[@]} >= JOBS)); then
    # Use wait -n for bash (supported in bash 4.3+)
    if wait -n 2>/dev/null; then
      # Flush finished repos' buffered output as one block each, keep running jobs
      new_job_logs=()
      for job in "${job_logs[@]}"; do
        if kill -0 "${job%%|*}" 2>/dev/null; then
          new_job_logs+=("$job")
        else
          flush_repo_log "${job#*|}"
        fi
      done
      job_logs=("${new_job_logs[@]}")
    else
      # Fallback for older bash versions
      wait
      for job in "${job_logs[@]}"; do
        flush_repo_log "${job#*|}"
      done
      job_logs=()
    fi
  fi
done

# Wait for all jobs to finish
wait

# 📦 Print buffered output from any jobs not yet flushed
for job in "${job_logs[@]}"; do
  flush_repo_log "${job#*|}"
done

# 🗑️ Clean up temporary logs
log_info "\n🗑️ Temporary files removed"
rm -rf "$LOG_DIR"
trap - EXIT

echo -e "\n🎉 All repositories updated!"
