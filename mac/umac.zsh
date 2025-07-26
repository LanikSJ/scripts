#!/usr/bin/env zsh
# umac.zsh - Universal Mac Update Script
# This script updates Brew, oh-my-zsh, Python, NPM, Ruby and GitHub Repos

# Icons for components
XCODE_ICON="🛠️"
BREW_ICON="🍺"
OMZ_ICON="🐚"
ZINIT_ICON="🔌"
PYTHON_ICON="🐍"
RUBY_ICON="💎"
NPM_ICON="📦"
GIT_ICON="📂"

# Icons for log types
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# Set strict error handling
set -e

# Disable glob expansion to prevent issues with special characters
set -f

# Handle script interruptions gracefully
trap 'echo -e "\n\033[0;31mScript interrupted. Exiting...\033[0m"; exit 1' INT TERM

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set default log file
LOG_FILE="$HOME/.umac_log"

# Log functions for consistent output
log_info() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "\n${BLUE}${INFO_ICON} INFO:${NC} $1"
  echo "[$timestamp] INFO: $1" >> "$LOG_FILE"
}

log_success() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "${GREEN}${SUCCESS_ICON} SUCCESS:${NC} $1"
  echo "[$timestamp] SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "${YELLOW}${WARNING_ICON} WARNING:${NC} $1"
  echo "[$timestamp] WARNING: $1" >> "$LOG_FILE"
}

log_error() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "${RED}${ERROR_ICON} ERROR:${NC} $1"
  echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
check_dependencies() {
  local missing_deps=()
  
  for cmd in jq git brew npm gem python3; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    log_info "Please install the missing dependencies and try again."
    exit 1
  fi
}

# Update Xcode command line tools
update_xcode() {
  log_info "${XCODE_ICON} Checking Xcode command line tools"
  
  if ! xcode-select -p &>/dev/null; then
    log_warning "Xcode command line tools not found. Installing..."
    xcode-select --install
    log_info "Please run this script again after Xcode command line tools installation completes."
    exit 0
  else
    log_success "Xcode command line tools are installed"
  fi
}

# Update Homebrew and packages
update_homebrew() {
  log_info "${BREW_ICON} Updating Homebrew"
  
  # Save current directory to return to it later
  local current_dir=$(pwd)
  
  # Check if HOMEBREW_PREFIX is set
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if command_exists brew; then
      HOMEBREW_PREFIX=$(brew --prefix)
    else
      log_error "HOMEBREW_PREFIX is not set and brew command not found"
      return 1
    fi
  fi
  
  cd "$HOMEBREW_PREFIX" || {
    log_error "Could not change to Homebrew directory: $HOMEBREW_PREFIX"
    return 1
  }
  
  # Update Homebrew itself
  git remote prune origin && git checkout main && git pull origin main
  
  log_info "${BREW_ICON} Updating Brew Packages & Casks"
  brew update || log_warning "Brew update failed"
  brew upgrade || log_warning "Brew upgrade failed"
  
  # Check if brew cu exists (part of homebrew-cask-upgrade)
  if brew cu --help &>/dev/null; then
    brew cu -ay --cleanup || log_warning "Brew cu failed"
  else
    log_warning "brew-cask-upgrade not installed. Skipping cask upgrades."
    log_info "Install with: brew tap buo/cask-upgrade"
  fi
  
  log_info "${BREW_ICON} Removing Homebrew Caches"
  brew cleanup -s --prune=1
  log_success "Homebrew cleanup completed"
  
  log_info "${BREW_ICON} Running Brew Doctor"
  brew doctor || log_warning "Brew doctor found issues"
  
  log_info "${BREW_ICON} Creating Brewfile"
  brew bundle dump --all --force --file=~/.Brewfile
  log_success "Brewfile created at ~/.Brewfile"
  
  log_info "${BREW_ICON} Cleaning up unneeded formulae"
  brew bundle cleanup --file=~/.Brewfile --force
  log_success "Brew cleanup completed"
  
  # Return to original directory
  cd "$current_dir" || log_warning "Could not return to original directory"
}

# Update Oh My ZSH
update_omz() {
  log_info "${OMZ_ICON} Updating Oh My ZSH"
  
  if [[ -z "$ZSH" ]]; then
    log_warning "ZSH variable not set. Assuming default location."
    ZSH="$HOME/.oh-my-zsh"
  fi
  
  if [[ ! -d "$ZSH" ]]; then
    log_warning "Oh My ZSH directory not found at $ZSH. Skipping."
    return 0
  fi
  
  local current_dir=$(pwd)
  cd "$ZSH" || {
    log_error "Could not change to Oh My ZSH directory: $ZSH"
    return 1
  }
  
  git pull || log_warning "Oh My ZSH update failed"
  
  cd "$current_dir" || log_warning "Could not return to original directory"
  log_success "Oh My ZSH updated"
}

# Update Zinit and plugins
update_zinit() {
  log_info "${ZINIT_ICON} Updating ZSH Plugins via Zinit"
  
  ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  
  if [[ ! -d "$ZINIT_HOME" ]]; then
    log_warning "Zinit not found at $ZINIT_HOME. Skipping."
    return 0
  fi
  
  # Source zinit if it exists
  if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
    # Run zinit update in a subshell to prevent environment changes from affecting our script
    (
      # Temporarily disable strict error handling for the subshell
      set +e
      
      # Save current directory
      local current_dir=$(pwd)
      
      # Source zinit
      source "${ZINIT_HOME}/zinit.zsh" 2>/dev/null
      
      if command_exists zinit; then
        zinit update --all 2>/dev/null || echo "Zinit update failed" >&2
      else
        echo "Zinit command not available after sourcing" >&2
      fi
      
      # Return to original directory
      cd "$current_dir" 2>/dev/null || true
    ) || log_warning "Zinit update process failed"
    
    # Clean up zcompdump files
    if ls "$HOME"/.zcompdump* 1> /dev/null 2>&1; then
      rm -rf "$HOME"/.zcompdump*
      log_success "Removed zcompdump files"
    fi
  else
    log_warning "Zinit script not found. Skipping."
  fi
  
  log_success "Zinit update process completed"
}

# Update Python packages
update_python() {
  log_info "${PYTHON_ICON} Updating Python packages"
  
  # Define excluded packages (can be a regex pattern)
  local exclude="(types-setuptools|pip|setuptools|wheel)"
  
  # Function to upgrade Python modules
  python_module_upgrade() {
    local python_version="$1"
    
    if ! command_exists "$python_version"; then
      log_warning "$python_version not found. Skipping."
      return 0
    fi
    
    log_info "${PYTHON_ICON} Updating $python_version packages"
    
    if ! "$python_version" -m pip --version &>/dev/null; then
      log_warning "$python_version pip not found. Skipping."
      return 0
    fi
    
    if ! command_exists jq; then
      log_warning "jq not found. Cannot parse pip JSON output. Skipping."
      return 0
    fi
    
    # Get only outdated packages to avoid unnecessary upgrades
    outdated_packages=$("$python_version" -m pip list --outdated --format=json 2>/dev/null | jq -r '.[].name' 2>/dev/null) || {
      log_warning "Failed to get outdated packages for $python_version"
      return 0
    }
    
    if [[ -z "$outdated_packages" ]]; then
      log_success "All packages are up to date for $python_version"
      return 0
    fi
    
    # Process packages one by one for better stability
    for pkg in $outdated_packages; do
      # Skip excluded packages
      if [[ -n "$exclude" && "$pkg" =~ $exclude ]]; then
        log_info "Skipping excluded package: $pkg"
        continue
      fi
      
      log_info "Upgrading $pkg"
      "$python_version" -m pip install -U "$pkg" || log_warning "Failed to upgrade $pkg"
    done
  }
  
  # Update packages for different Python versions
  python_module_upgrade "python3"
  python_module_upgrade "python3.13"
  
  # Freeze Python 3 packages
  log_info "${PYTHON_ICON} Freezing Python 3 packages"
  
  # Create pip directory if it doesn't exist
  mkdir -p "$HOME/.pip"
  
  if python3 -m pip freeze > "$HOME/.pip/pip3.txt"; then
    log_success "Python packages frozen to ~/.pip/pip3.txt"
  else
    log_error "Failed to freeze Python packages"
    return 1
  fi
}

# Update Ruby gems
update_ruby() {
  log_info "${RUBY_ICON} Updating Ruby Gems"
  
  if ! command_exists gem; then
    log_warning "Ruby gem command not found. Skipping."
    return 0
  fi
  
  # Update RubyGems system
  gem update --system || log_warning "Failed to update RubyGems system"
  
  # Update all gems
  gem update || log_warning "Failed to update gems"
  
  # Clean up old gems
  gem cleanup || log_warning "Failed to clean up gems"
  
  log_success "Ruby gems updated"
  
  # Uncomment if using RVM
  # if command_exists rvm; then
  #   log_info "Updating gems for all RVM gemsets"
  #   rvm all-gemsets do gem update
  #   rvm all-gemsets do gem cleanup
  # fi
}

# Update NPM packages
update_npm() {
  log_info "${NPM_ICON} Updating NPM packages"
  
  if ! command_exists npm; then
    log_warning "npm command not found. Skipping."
    return 0
  fi
  
  # Update corepack separately as it requires special handling
  log_info "${NPM_ICON} Updating corepack"
  npm install -g corepack@latest || log_warning "Failed to update corepack"
  
  # Update global npm packages
  log_info "${NPM_ICON} Updating NPM global packages"
  
  # Get list of outdated global packages
  local outdated_packages
  if outdated_packages=$(npm outdated -g --json 2>/dev/null | jq -r 'keys[]' 2>/dev/null); then
    if [[ -z "$outdated_packages" ]]; then
      log_success "All global NPM packages are up to date"
    else
      # Update each package individually
      for pkg in $outdated_packages; do
        # Skip corepack as it's already updated separately
        if [[ "$pkg" == "corepack" ]]; then
          continue
        fi
        
        log_info "Updating global package: $pkg"
        npm install -g "$pkg@latest" || log_warning "Failed to update global package: $pkg"
      done
      log_success "Global NPM packages updated"
    fi
  else
    log_warning "Failed to check for outdated global npm packages"
  fi
  
  # Determine NPM modules directory
  local NPM_DIR
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    NPM_DIR="$HOMEBREW_PREFIX/lib/node_modules"
  else
    NPM_DIR="/usr/local/lib/node_modules"
    log_warning "HOMEBREW_PREFIX not set, using default NPM directory: $NPM_DIR"
  fi
  
  if [[ ! -d "$NPM_DIR" ]]; then
    log_warning "NPM directory not found: $NPM_DIR. Skipping."
    return 0
  fi
  
  # Update individual npm packages
  local current_dir=$(pwd)
  
  for pkg_dir in "$NPM_DIR"/*; do
    if [[ -d "$pkg_dir" && "$(basename "$pkg_dir")" != "npm" && "$(basename "$pkg_dir")" != "adguard" ]]; then
      local pkg_name=$(basename "$pkg_dir")
      log_info "Updating $pkg_name"
      
      cd "$pkg_dir" || {
        log_warning "Could not change to directory: $pkg_dir"
        continue
      }
      
      npm update || log_warning "Failed to update $pkg_name"
    fi
  done
  
  # Special case for AGLint
  if [[ -d "$NPM_DIR/@adguard/aglint" ]]; then
    log_info "Updating AGLint"
    cd "$NPM_DIR/@adguard/aglint" || log_warning "Could not change to AGLint directory"
    npm update || log_warning "Failed to update AGLint"
  fi
  
  # Return to original directory
  cd "$current_dir" || log_warning "Could not return to original directory"
  
  # Clear npm cache
  log_info "${NPM_ICON} Clearing NPM cache"
  npm cache clean --force || log_warning "Failed to clear npm cache"
  
  log_success "NPM packages updated"
}

# Update Git repositories
update_git_repos() {
  local repo_dir="$1"
  local dir_name="$2"
  
  log_info "${GIT_ICON} Updating $dir_name repositories"
  
  if [[ ! -d "$repo_dir" ]]; then
    log_warning "$dir_name directory not found: $repo_dir. Skipping."
    return 0
  fi
  
  local current_dir=$(pwd)
  
  for repo in "$repo_dir"/*/; do
    if [[ -d "$repo/.git" ]]; then
      local repo_name=$(basename "$repo")
      log_info "${GIT_ICON} Updating $repo_name"
      
      cd "$repo" || {
        log_warning "Could not change to repository: $repo"
        continue
      }
      
      git remote prune origin || log_warning "Failed to prune remote for $repo_name"
      git pull || log_warning "Failed to pull updates for $repo_name"
    fi
  done
  
  cd "$current_dir" || log_warning "Could not return to original directory"
  log_success "$dir_name repositories updated"
}

# Main function to run all updates
main() {
  # Process command line arguments
  local skip_components=()
  local run_only=""
  local custom_log_file=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip=*)
        skip_components+=(${1#*=})
        ;;
      --only=*)
        run_only=${1#*=}
        ;;
      --log=*)
        custom_log_file=${1#*=}
        ;;
      --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --skip=COMPONENT   Skip updating specified component (xcode, brew, omz, zinit, python, ruby, npm, git)"
        echo "  --only=COMPONENT   Only update specified component (xcode, brew, omz, zinit, python, ruby, npm, git)"
        echo "  --log=FILE         Specify a custom log file (default: ~/.umac_log)"
        echo "  --help             Show this help message"
        return 0
        ;;
      *)
        log_warning "Unknown option: $1"
        ;;
    esac
    shift
  done
  
  # Set custom log file if provided
  if [[ -n "$custom_log_file" ]]; then
    LOG_FILE="$custom_log_file"
  fi
  
  # Create or truncate log file
  echo "# UMAC Log - $(date)" > "$LOG_FILE"
  
  log_info "🚀 Starting system update process"
  log_info "Logging to $LOG_FILE"
  
  # Check for dependencies
  check_dependencies
  
  # Function to check if a component should be skipped
  should_skip() {
    local component="$1"
    for skip in "${skip_components[@]}"; do
      if [[ "$skip" == "$component" ]]; then
        return 0
      fi
    done
    
    if [[ -n "$run_only" && "$run_only" != "$component" ]]; then
      return 0
    fi
    
    return 1
  }
  
  # Update components
  should_skip "xcode" || update_xcode
  should_skip "brew" || update_homebrew
  should_skip "omz" || update_omz
  should_skip "zinit" || update_zinit
  should_skip "python" || update_python
  should_skip "ruby" || update_ruby
  should_skip "npm" || update_npm
  
  # Update Git repositories
  if ! should_skip "git"; then
    update_git_repos "$HOME/GitHub/LanikSJ" "LanikSJ"
    update_git_repos "$HOME/GitHub/Mac" "Mac"
    update_git_repos "$HOME/.vim/plugged" "VIM Plugged"
  fi
  
  log_success "🎉 System update completed successfully!"
}

# Run the main function
main "$@"
