#!/usr/bin/env bash
# -----------------------------------------------------------------------
# dropbox-safe.sh - Make a Dropbox-synced git repo safe from sync
# -----------------------------------------------------------------------
# Usage: ./dropbox-safe.sh [--dry-run] [--verbose] [--help] [repo_path]
#
# Moves the .git directory of a repository out of Dropbox (or any other
# sync'd folder) into ~/.gitdirs/<name>.git and leaves a .git pointer
# file behind (the same mechanism submodules and git worktrees use).
#
# Why: cloud sync clients (Dropbox, iCloud, OneDrive) treat .git/refs
# as ordinary files and can resurrect deleted branch refs, silently
# undoing branch cleanup (gcpd.sh, git branch -D, etc.).
#
# Options:
#   --dry-run   Show what would be done without making changes
#   --verbose   Show detailed information during execution
#   --help      Show this help message
#
# Arguments:
#   repo_path   Repository to convert (defaults to current directory)
#
# Result:
#   ~/Dropbox/repo/          working tree (still synced)
#   ~/Dropbox/repo/.git      pointer file -> ~/.gitdirs/repo.git
#   ~/.gitdirs/repo.git      git metadata (NOT synced, safe from resurrection)
# -----------------------------------------------------------------------
# shellcheck disable=SC2317

set -euo pipefail

GITDIRS_HOME="${GITDIRS_HOME:-$HOME/.gitdirs}"

# Default configuration
VERBOSE=false
DRY_RUN=false
REPO_PATH=""

# -----------------------------------------------------------------------
# Logging functions (emoji icons for visual scannability)
# -----------------------------------------------------------------------
log_info() {
  echo "ℹ️ $1"
}

log_success() {
  echo "✅ $1"
}

log_warning() {
  echo "⚠️ $1"
}

log_error() {
  echo "❌ $1" >&2
}

log_verbose() {
  if [[ "$VERBOSE" == true ]]; then
    echo "🔍 $1"
  fi
}

# -----------------------------------------------------------------------
# Help function
# -----------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--verbose] [--help] [repo_path]

Make a Dropbox-synced git repo safe from sync clients resurrecting
deleted branch refs by moving .git metadata to ${GITDIRS_HOME}/.

Options:
  --dry-run   Show what would be done without making changes
  --verbose   Show detailed information during execution
  --help      Show this help message

Arguments:
  repo_path   Repository to convert (defaults to current directory)

Environment:
  GITDIRS_HOME  Where git metadata is stored (default: ~/.gitdirs)

Examples:
  $(basename "$0") ~/GitHub/Sloths   # convert a specific repo
  cd ~/GitHub/Sloths && $(basename "$0")  # convert current repo
EOF
}

# -----------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      log_info "DRY RUN MODE: No changes will be made"
      ;;
    --verbose)
      VERBOSE=true
      ;;
    --help)
      usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $arg"
      usage
      exit 1
      ;;
    *)
      REPO_PATH="$arg"
      ;;
  esac
done

# Default to current directory
if [[ -z "$REPO_PATH" ]]; then
  REPO_PATH="$(pwd)"
fi

# -----------------------------------------------------------------------
# Validation functions
# -----------------------------------------------------------------------
check_directory() {
  if [[ ! -d "$1" ]]; then
    log_error "Directory does not exist: $1"
    exit 1
  fi
}

check_git_repo() {
  if ! git -C "$1" rev-parse --is-inside-work-tree &>/dev/null; then
    log_error "Not a git repository: $1"
    exit 1
  fi
}

# -----------------------------------------------------------------------
# Main conversion function
# -----------------------------------------------------------------------
convert_repo() {
  local repo_path="$1"
  local repo_name
  local gitdir_target
  local gitdir_current

  check_directory "$repo_path"
  check_git_repo "$repo_path"

  repo_name="$(basename "$(cd "$repo_path" && pwd -P)")"
  gitdir_target="${GITDIRS_HOME}/${repo_name}.git"

  gitdir_current="$(git -C "$repo_path" rev-parse --git-dir)"
  # Resolve to absolute path for comparison
  if [[ "$gitdir_current" != /* ]]; then
    gitdir_current="$(cd "$repo_path" && cd "$gitdir_current" && pwd -P)"
  fi

  log_info "Repository: $repo_path"
  log_info "Git metadata currently at: $gitdir_current"

  # Check if already converted (gitdir already outside the repo)
  if [[ "$gitdir_current" == "$gitdir_target" ]]; then
    log_success "Already converted: git metadata is at $gitdir_target"
    return 0
  fi

  # Check if .git is already a pointer file (but pointing elsewhere)
  if [[ -f "$repo_path/.git" ]]; then
    log_warning ".git is already a pointer file: $(cat "$repo_path/.git")"
    log_info "Use a fresh conversion if this needs to be changed manually"
    return 1
  fi

  # Ensure .git is a directory (not a submodule or worktree)
  if [[ ! -d "$repo_path/.git" ]]; then
    log_error "No .git directory found in $repo_path"
    return 1
  fi

  # Check for existing target
  if [[ -d "$gitdir_target" ]]; then
    log_error "Target gitdir already exists: $gitdir_target"
    log_info "Remove it or choose a different name if intentional"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "Would move: $gitdir_current -> $gitdir_target"
    log_info "Would create pointer: $repo_path/.git -> gitdir: $gitdir_target"
    return 0
  fi

  # Create gitdirs parent directory
  mkdir -p "$GITDIRS_HOME"
  log_verbose "Created/verified directory: $GITDIRS_HOME"

  # Move .git to gitdirs
  log_info "Moving git metadata to $gitdir_target..."
  mv "$gitdir_current" "$gitdir_target"
  log_success "Moved git metadata"

  # Create pointer file
  printf 'gitdir: %s\n' "$gitdir_target" > "$repo_path/.git"
  log_success "Created .git pointer file"

  # Verify conversion
  log_info "Verifying conversion..."
  if git -C "$repo_path" rev-parse --git-dir &>/dev/null &&
    [[ "$(git -C "$repo_path" rev-parse --git-dir)" == "$gitdir_target" ]]; then
    log_success "Conversion verified: git metadata is at $gitdir_target"
    log_success "Working tree remains at $repo_path (still synced)"
  else
    log_error "Verification failed - check $repo_path/.git"
    return 1
  fi
}

# -----------------------------------------------------------------------
# Main execution
# -----------------------------------------------------------------------
main() {
  convert_repo "$REPO_PATH"
  log_success "Operation completed successfully"
}

# Run main function
main
