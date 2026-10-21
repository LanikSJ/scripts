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
VIM_ICON="📝"
MACOS_ICON="🍎"

# Icons for log types
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"
CLEAN_ICON="🧹"

# Disable glob expansion to prevent issues with special characters
set -f

# Configuration

# Array to track temporary files and directories for cleanup
TEMP_FILES=()

# Cleanup function to remove temporary files and logs
cleanup_temp_files() {
  if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
    log_info "🧹 Temporary files removed"
    for temp_item in "${TEMP_FILES[@]}"; do
      if [[ -e "$temp_item" ]]; then
        rm -rf "$temp_item" 2>/dev/null || true
      fi
    done
    TEMP_FILES=()
  fi
}

# Handle script interruptions gracefully
trap 'echo -e "\nScript interrupted. Cleaning up..."; cleanup_temp_files; exit 1' INT TERM

# Handle script exit to ensure cleanup on successful completion
trap 'cleanup_temp_files' EXIT


# Log functions for consistent output
log_info() {
  echo -e "$1"
}

log_success() {
  echo -e "✅ $1"
}

log_warning() {
  echo -e "⚠️ $1"
}

log_error() {
  echo -e "❌ $1"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if brew subcommand exists
brew_subcommand_exists() {
  brew "$1" --help >/dev/null 2>&1
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
  log_info "\n${XCODE_ICON} Checking Xcode command line tools"

  if ! xcode-select -p &>/dev/null; then
    log_warning "\n${XCODE_ICON} Xcode command line tools not found. Installing..."
    xcode-select --install
    log_info "Please run this script again after Xcode command line tools installation completes."
    exit 0
  else
    log_success "Xcode command line tools are installed"
  fi
}

# Update Homebrew and packages
update_homebrew() {
  log_info "\n${BREW_ICON} Updating Homebrew"

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

  log_info "\n${BREW_ICON} Updating Brew Packages & Casks"
  brew update --auto-update || log_warning "Brew update failed"
  brew upgrade -y || log_warning "Brew upgrade failed"

  # Check if brew cu exists (part of homebrew-cask-upgrade)
  if brew_subcommand_exists cu; then
    brew cu -ay --include-mas || log_warning "Brew cask upgrade failed"
  else
    log_warning "brew-cask-upgrade not installed."
    log_info "Installing with: brew tap buo/cask-upgrade"
    brew tap buo/cask-upgrade || log_warning "Failed to tap buo/cask-upgrade"
    brew cu -ay --include-mas || log_warning "Brew cask upgrade failed"
  fi

  log_info "\n${BREW_ICON} Removing Homebrew Caches"
  brew cleanup -s --prune=1
  log_success "Homebrew cleanup completed"

  log_info "\n${BREW_ICON} Running Brew Doctor"
  brew doctor || log_warning "Brew doctor found issues"

  log_info "\n${BREW_ICON} Creating Brewfile"
  brew bundle dump --force --file=~/.Brewfile
  log_success "Brewfile created at ~/.Brewfile"

  log_info "\n${BREW_ICON} Cleaning up unneeded formulae"
  brew bundle cleanup --file=~/.Brewfile --force
  log_success "Brew cleanup completed"

  # Return to original directory
  cd "$current_dir" || log_warning "Could not return to original directory"
}

# Update Oh My ZSH
update_omz() {
  log_info "\n${OMZ_ICON} Updating Oh My ZSH"

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
  log_info "\n${ZINIT_ICON} Updating ZSH Plugins via Zinit"

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

      # Source zinit
      source "${ZINIT_HOME}/zinit.zsh" 2>/dev/null

      if command_exists zinit; then
        zinit self-update 2>/dev/null || echo "Zinit self-update failed" >&2
        zinit update -a -p 2>/dev/null || echo "Zinit update failed" >&2
      else
        echo "Zinit command not available after sourcing" >&2
      fi
    ) || log_warning "Zinit update process failed"

    # Clean up zcompdump files
    if find "$HOME" -maxdepth 1 -name '.zcompdump*' 1> /dev/null 2>&1; then
      find "$HOME" -maxdepth 1 -name '.zcompdump*' -delete 2>/dev/null
      log_success "Removed zcompdump files"
    fi
  else
    log_warning "Zinit script not found. Skipping."
  fi

  log_success "Zinit update process completed"
}

# Update Python packages
update_python() {
  log_info "\n${PYTHON_ICON} Updating Python packages"

  # Define excluded packages (can be a regex pattern)
  local exclude="(pip|setuptools|wheel)"

  # Function to detect installed Python versions
  detect_python_versions() {
    log_info "${PYTHON_ICON} Auto-detecting Python versions" >&2
    local detected_versions=()

    # Check for python3
    if command_exists python3; then
      detected_versions+=("python3")
    fi

    # Check for specific Python 3 versions (3.7 through 3.14)
    for version in {7..14}; do
      if command_exists "python3.$version"; then
        detected_versions+=("python3.$version")
      fi
    done

    # If no Python versions found, warn the user
    if [[ ${#detected_versions[@]} -eq 0 ]]; then
      log_warning "No Python versions detected on this system." >&2
      return 1
    fi

    log_success "Detected Python versions: ${detected_versions[*]}" >&2

    # Return the detected versions as a space-separated string
    local output=""
    for version in "${detected_versions[@]}"; do
      output+="$version "
    done
    echo -n "${output% }"  # Remove trailing space
  }

  # Function to upgrade Python modules
  python_module_upgrade() {
    local python_version="$1"

    if ! command_exists "$python_version"; then
      log_warning "$python_version not found. Skipping."
      return 0
    fi

    log_info "${PYTHON_ICON} Updating $python_version packages"

    if ! "$python_version" -m pip --isolated --version &>/dev/null; then
      log_warning "$python_version pip not found. Skipping."
      return 0
    fi

    # Clear pip cache
    log_info "${CLEAN_ICON} Clearing pip cache for $python_version..."
    "$python_version" -m pip --isolated cache purge || log_warning "Failed to clear pip cache for $python_version"

    # Update pip itself first
    log_info "${PYTHON_ICON} Updating pip for $python_version..."
    "$python_version" -m pip install -U pip || log_warning "Failed to update pip for $python_version"

    if ! command_exists jq; then
      log_warning "jq not found. Cannot parse pip JSON output. Skipping."
      return 0
    fi

    # Get only outdated packages to avoid unnecessary upgrades
    outdated_packages=$("$python_version" -m pip --isolated list --outdated --format=json 2>/dev/null | jq -r '.[].name' 2>/dev/null) || {
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
      "$python_version" -m pip install -U -v "$pkg" || log_warning "Failed to upgrade $pkg"
    done
  }

  # Auto-detect Python versions
  local python_versions=()
  IFS=' ' read -A python_versions <<< "$(detect_python_versions)"

  # If no Python versions were detected, exit
  if [[ ${#python_versions[@]} -eq 0 ]]; then
    log_error "No Python versions found. Please install Python."
    return 1
  fi

  # Update packages for each detected Python version
  for python_version in "${python_versions[@]}"; do
    python_module_upgrade "$python_version"
  done

  # Freeze Python 3 packages
  log_info "${PYTHON_ICON} Freezing Python 3 packages"

  # Create pip directory if it doesn't exist
  mkdir -p "$HOME/.pip"

  if python3 -m pip --isolated freeze > "$HOME/.pip/pip3.txt"; then
    log_success "Python packages frozen to ~/.pip/pip3.txt"
  else
    log_error "Failed to freeze Python packages"
    return 1
  fi
}

# Update Ruby gems
update_ruby() {
  log_info "\n${RUBY_ICON} Updating Ruby Gems"

  if ! command_exists gem; then
    log_warning "${RUBY_ICON} Ruby gem command not found. Skipping."
    return 0
  fi

  # Fix RDoc: stale/broken rdoc gemspec stubs in the default gem home crash every
  # gem command (list, uninstall, install, update, cleanup), so they must be removed.
  #
  # The old logic deleted EVERY rdoc gemspec up front and then only reinstalled when
  # rdoc had been missing *before* that deletion. A healthy install therefore got
  # destroyed on one run and reinstalled on the next, forever (install ping-pong).
  # Now: a healthy rdoc is left untouched; cleanup + (re)install only happen when
  # rdoc is actually missing or its stubs are broken.
  #
  # Uninstall rdoc from the Cellar path first if an old 7.0.x version is present
  # (avoids conflicts between Cellar and the default gem home). The Cellar version
  # dir may carry a revision suffix (e.g. 4.0.7_1), so resolve it with find instead
  # of assuming RUBY_VERSION.
  local ruby_version
  ruby_version=$(ruby -e 'print RUBY_VERSION' 2>/dev/null)
  local ruby_cellar rdoc_dir=""
  ruby_cellar=$(brew --cellar ruby 2>/dev/null)
  if [[ -n "$ruby_cellar" && -d "$ruby_cellar" ]]; then
    local cellar_dir
    cellar_dir=$(find "$ruby_cellar" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
    [[ -n "$cellar_dir" ]] && rdoc_dir="${cellar_dir}/lib/ruby/gems/${ruby_version%.*}.0"
  fi

  # Only run the uninstall when an rdoc-7.0.x dir actually exists. The old
  # `find ... | head -1 >/dev/null` guard always succeeded (the pipeline status is
  # head's, which is 0 even with no input), so the uninstall ran unconditionally
  # and printed "Gem 'rdoc' is not installed" on every update.
  if [[ -n "$rdoc_dir" ]] && [[ -n "$(find "${rdoc_dir}/gems" -maxdepth 1 -name 'rdoc-7.0.*' -print -quit 2>/dev/null)" ]]; then
    # Create bin directory if missing (fixes "No write perm" error)
    if [[ ! -d "${rdoc_dir}/bin" ]]; then
      mkdir -p "${rdoc_dir}/bin"
    fi
    yes | gem uninstall -i "${rdoc_dir}" --ignore-dependencies rdoc || true
    # Clean stale rdoc plugin in Cellar path that causes LoadError
    rm -f "${rdoc_dir}/plugins/rdoc_plugin.rb" 2>/dev/null || true
  fi

  local gem_home
  gem_home=$(gem environment gemdir 2>/dev/null)

  if gem list --local -e rdoc -i >/dev/null 2>&1; then
    # rdoc is healthy — drop only orphaned stubs (gemspec whose gems dir is gone)
    if [[ -n "$gem_home" && -d "${gem_home}/specifications" ]]; then
      local spec base
      while IFS= read -r spec; do
        [[ -n "$spec" ]] || continue
        base=$(basename "$spec" .gemspec)
        if [[ ! -d "${gem_home}/gems/${base}" ]]; then
          log_info "Removing orphaned rdoc stub: $(basename "$spec")"
          rm -f "$spec" 2>/dev/null || true
        fi
      done < <(find "${gem_home}/specifications" -maxdepth 1 -name 'rdoc-*.gemspec' 2>/dev/null)
    fi
    log_success "rdoc is installed ($(gem list --local -e rdoc 2>/dev/null | head -1 | tr -d ' '))"
  else
    # rdoc missing or its stubs are broken — remove ALL rdoc stubs/plugins so a
    # corrupt gemspec cannot break the reinstall, then install fresh
    if [[ -n "$gem_home" ]]; then
      find "${gem_home}/specifications" -maxdepth 1 -name 'rdoc-*.gemspec' -delete 2>/dev/null || true
      rm -f "${gem_home}/plugins/rdoc_plugin.rb" 2>/dev/null || true
    fi
    log_info "${RUBY_ICON} Installing rdoc..."
    gem install rdoc || log_warning "Failed to install rdoc"
  fi

  # Update RubyGems system
  gem update --system || log_warning "Failed to update ${RUBY_ICON} RubyGems system"

  # Update all gems
  gem update || log_warning "Failed to update gems"

  # Clean up old gems
  gem cleanup || log_warning "Failed to clean up gems"

  log_success "Ruby Gems ${RUBY_ICON} Updated"
}

# Update NPM packages
update_npm() {
  log_info "\n${NPM_ICON} Updating NPM packages"

  if ! command_exists npm; then
    log_warning "npm command not found. Skipping."
    return 0
  fi

  # Check if npm-check is installed
  if ! command_exists npm-check; then
    log_info "\n${NPM_ICON} npm-check is not installed. Installing it globally..."
    if npm install -g npm-check; then
      log_success "npm-check installed successfully."
    else
      log_warning "Failed to install npm-check. Falling back to standard npm update."
      # Fall back to standard npm update method
      update_npm_standard
      return 0
    fi
  fi

  # Update global npm packages using npm-check
  log_info "\n${NPM_ICON} Updating NPM global packages using npm-check"

  # First, get a list of all global packages except corepack and npm-check
  local global_packages
  if ! global_packages=$(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[] | select(. != "corepack" and . != "npm-check")' 2>/dev/null); then
    log_warning "Failed to get list of global packages. Falling back to standard method."
    update_npm_standard
    return 0
  fi

  # Check if there are any packages to update
  if [[ -z "$global_packages" ]]; then
    log_success "No global packages to update (excluding corepack and npm-check)"
    return 0
  fi

  # Update each package individually using npm-check
  log_info "\n${NPM_ICON} Updating global packages individually (excluding corepack and npm-check)"
  local update_count=0
  local fail_count=0

  # Save current directory to return to it later
  local current_dir=$(pwd)

  # Create a temporary directory for npm-check operations
  local tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  cd "$tmp_dir" || {
    log_warning "Could not create temporary directory for npm-check operations"
    cd "$current_dir"
    update_npm_standard
    return 0
  }

  # Update each package individually using npm-check
  for pkg in $global_packages; do
    log_info "Checking ${pkg}..."

    # Run npm-check with error handling - use --minor flag to update only minor versions (no new installs)
    { npm-check -g -u -y --skip-unused --minor --no-install "$pkg" ; } > /dev/null 2>&1 || true

    # Check if the package was updated by checking if it's still outdated
    if npm outdated -g "$pkg" | grep -q "$pkg"; then
      log_warning "Failed to update ${pkg} with npm-check"
      ((fail_count++))
    else
      log_success "Updated ${pkg} successfully"
      ((update_count++))
    fi
  done

  # Return to original directory
  cd "$current_dir" || log_warning "Could not return to original directory"
  rm -rf "$tmp_dir"

  if [[ $update_count -gt 0 ]]; then
    log_success "Updated $update_count global packages with npm-check (excluding corepack and npm-check)"
  else
    log_info "${NPM_ICON} No packages were updated with npm-check"
  fi

  # Determine NPM modules directory
  local NPM_DIR
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    NPM_DIR="$HOMEBREW_PREFIX/lib/node_modules"
  else
    NPM_DIR="/usr/local/lib/node_modules"
    log_warning "${BREW_ICON} HOMEBREW_PREFIX not set, using default NPM directory: $NPM_DIR"
  fi

  if [[ ! -d "$NPM_DIR" ]]; then
    log_warning "${NPM_ICON} NPM directory not found: $NPM_DIR. Skipping."
    return 0
  fi

  # Update individual npm packages using npm-check
  local current_dir=$(pwd)
  local module_update_count=0
  local module_fail_count=0

  # Create a temporary directory for npm-check operations
  local tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")

  for pkg_dir in "$NPM_DIR"/*; do
    if [[ -d "$pkg_dir" && "$(basename "$pkg_dir")" != "npm" && "$(basename "$pkg_dir")" != "adguard" && "$(basename "$pkg_dir")" != "npm-check" && "$(basename "$pkg_dir")" != "corepack" ]]; then
      local pkg_name=$(basename "$pkg_dir")
      log_info "\n${NPM_ICON} Updating $pkg_name using npm-check"

      # Change to the package directory
      if cd "$pkg_dir"; then
        # Run npm-check with error handling - use --minor flag to update only minor versions (no new installs)
        { npm-check -u -y --skip-unused --minor --no-install ; } > /dev/null 2>&1 || true

        if [[ $? -eq 0 ]]; then
          log_success "Updated $pkg_name successfully"
          ((module_update_count++))
        else
          log_warning "Failed to update $pkg_name with npm-check"
          ((module_fail_count++))
        fi

        # Return to tmp directory
        cd "$tmp_dir"
      else
        log_warning "Could not change to directory: $pkg_dir"
        ((module_fail_count++))
      fi
    fi
  done

  # Special case for AGLint
  if [[ -d "$NPM_DIR/@adguard/aglint" ]]; then
    log_info "\n${NPM_ICON} Updating AGLint using npm-check"

    if cd "$NPM_DIR/@adguard/aglint"; then
      # Run npm-check with error handling - use --minor flag to update only minor versions (no new installs)
      { npm-check -u -y --skip-unused --minor --no-install ; } > /dev/null 2>&1 || true

      if [[ $? -eq 0 ]]; then
        log_success "Updated AGLint successfully"
        ((module_update_count++))
      else
        log_warning "Failed to update AGLint with npm-check"
        ((module_fail_count++))
      fi

      # Return to tmp directory
      cd "$tmp_dir"
    else
      log_warning "Could not change to AGLint directory"
      ((module_fail_count++))
    fi
  fi

  # Clean up temporary directory
  rm -rf "$tmp_dir"

  # Log summary of module updates
  if [[ $module_update_count -gt 0 ]]; then
    log_success "Updated $module_update_count individual modules with npm-check"
  fi
  if [[ $module_fail_count -gt 0 ]]; then
    log_warning "${NPM_ICON} Failed to update $module_fail_count individual modules"
  fi

  # Return to original directory
  cd "$current_dir" || log_warning "Could not return to original directory"

  # Clear npm cache
  log_info "\n${NPM_ICON} Clearing NPM cache"
  npm cache clean --force || log_warning "Failed to clear npm cache"

  log_success "NPM packages updated with npm-check"
}

# Fallback method using standard npm commands
update_npm_standard() {
  log_info "${NPM_ICON} Using standard npm update method"

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
    log_warning "${BREW_ICON} HOMEBREW_PREFIX not set, using default NPM directory: $NPM_DIR"
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
}

# 📦 Flush a finished repo's buffered output as one atomic block (shared with ugh.sh)
flush_repo_log() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cat "$file"
    rm -f "$file"
  fi
}

# 🛠️ Git update function (shared with ugh.sh)
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

# Update Git repositories
update_git_repos() {
  local repo_dir="$1"
  local dir_name="$2"

  # Special formatting for VIM Plugged repositories
  if [[ "$dir_name" == "VIM Plugged" ]]; then
    log_info "\n${GIT_ICON} Updating ${VIM_ICON} VIM Plugged repositories"
  else
    log_info "\n${GIT_ICON} Updating $dir_name repositories"
  fi

  if [[ ! -d "$repo_dir" ]]; then
    log_warning "$dir_name directory not found: $repo_dir. Skipping."
    return 0
  fi

  # Build repo list
  local repolist=()
  for dir in "$repo_dir"/*; do
    [[ -d "$dir/.git" ]] && repolist+=("$(basename "$dir")")
  done

  # Check if there are any repositories to update
  if [[ ${#repolist[@]} -eq 0 ]]; then
    log_warning "No git repositories found in $repo_dir"
    return 0
  fi

  log_info "Found ${#repolist[@]} repositories to update in $dir_name"

  local current_dir=$(pwd)

  # 🧵 Parallel update (default: one job per CPU core, override with UGH_JOBS)
  local JOBS="${UGH_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
  # 📦 Buffer each repo's output so parallel jobs don't interleave on the terminal
  local log_dir
  log_dir="$(mktemp -d)"
  TEMP_FILES+=("$log_dir")
  local repo_log
  local job_logs=()
  local new_job_logs
  for repo in "${repolist[@]}"; do
    repo_log="$log_dir/$repo.log"
    (
      cd "$repo_dir/$repo" || {
        log_error "Could not change to repository: $repo_dir/$repo"
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
      log_success "$repo updated and cleaned"
    ) >"$repo_log" 2>&1 &
    job_logs+=("$!|$repo_log")
    # Limit parallel jobs - cross-shell compatible version
    if (( ${#job_logs[@]} >= JOBS )); then
      # Use wait -n where supported (bash 4.3+)
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
        # Fallback for shells without wait -n (e.g. zsh, bash 3.2)
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

  cd "$current_dir" || log_warning "Could not return to original directory"

  # Special formatting for VIM Plugged repositories
  if [[ "$dir_name" == "VIM Plugged" ]]; then
    echo ""
    log_success "VIM ${VIM_ICON} Plugged repositories updated"
  else
    log_success "$dir_name repositories updated"
  fi
}

# Check for macOS updates
update_macos() {
  log_info "\n${MACOS_ICON} Checking for macOS updates"

  # Check if softwareupdate command exists
  if ! command_exists softwareupdate; then
    log_error "softwareupdate command not found. Cannot check for macOS updates."
    return 1
  fi

  # Trigger background scan and update operation (non-blocking, no sudo required)
  log_info "${MACOS_ICON} Triggering background update scan and download..."
  if softwareupdate --background --force 2>/dev/null; then
    log_success "Background update scan and download triggered successfully"
  else
    log_warning "Background update trigger returned non-zero (may already be running or no updates available)"
  fi

  # Check for available updates (list what's pending)
  local updates_output
  updates_output=$(softwareupdate -l 2>&1)
  local exit_code=$?

  # Check if there was an error
  if [[ $exit_code -ne 0 ]]; then
    if [[ "$updates_output" == *"No new software available"* ]]; then
      log_success "Your macOS is up to date"
      return 0
    else
      log_error "Failed to check for macOS updates: $updates_output"
      return 1
    fi
  fi

  # If we get here, there are updates available
  if [[ "$updates_output" == *"No new software available"* ]]; then
    log_success "Your macOS is up to date"
  else
    log_warning "macOS updates are available (background download in progress):"
    echo "$updates_output" | grep -v "^$" | sed 's/^/    /'

    log_info "Updates are being downloaded in the background and will install automatically."
    log_info "Some updates may require a restart to complete installation."
  fi

  return 0
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
      --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --skip=COMPONENT   Skip updating specified component (xcode, macos, brew, omz, zinit, python, ruby, npm, git)"
        echo "  --only=COMPONENT   Only update specified component (xcode, macos, brew, omz, zinit, python, ruby, npm, git)"
        echo "  --help             Show this help message"
        return 0
        ;;
      *)
        log_warning "Unknown option: $1"
        ;;
    esac
    shift
  done

  log_info "🚀 Starting system update process"

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
  should_skip "macos" || update_macos
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

  log_success "System update completed successfully! 🎉"
}

# Run the main function
main "$@"
