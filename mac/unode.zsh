#!/usr/bin/env zsh
# This script will update Node Modules

# Icons for better visual output
INFO_ICON="ℹ️ "
SUCCESS_ICON="✅ "
WARNING_ICON="⚠️ "
ERROR_ICON="❌ "
PACKAGE_ICON="📦 "
NODE_ICON="⬢ "
UPDATE_ICON="🔄 "
CONFIG_ICON="⚙️ "

# Default configuration
typeset -a EXCLUDE_MODULES=("corepack")  # Exclude corepack by default
VERBOSE=false
DRY_RUN=false
SKIP_CONFIRM=true
GLOBAL_ONLY=false

# Help function
show_help() {
  cat << EOF
${NODE_ICON} unode.zsh - Node Modules Updater

Usage: unode.zsh [options]

Options:
  -h, --help           Show this help message and exit
  -e, --exclude LIST   Comma-separated list of modules to exclude from updates
  -v, --verbose        Enable verbose output
  -d, --dry-run        Show what would be updated without making changes
  -y, --yes            Skip confirmation prompt
  -g, --global-only    Only update global npm, skip individual modules

Example:
  unode.zsh --exclude "gulp,webpack" --verbose
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -e|--exclude)
      IFS=',' read -A EXCLUDE_MODULES <<< "$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -g|--global-only)
      GLOBAL_ONLY=true
      shift
      ;;
    *)
      echo "${ERROR_ICON} Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check if npm and npm-check are installed
check_dependencies() {
  if ! command -v npm &> /dev/null; then
    echo "${ERROR_ICON} Error: npm is not installed. Please install Node.js first."
    exit 1
  fi
  
  if ! command -v npm-check &> /dev/null; then
    echo "${INFO_ICON} npm-check is not installed. Installing it globally..."
    if npm install -g npm-check; then
      echo "${SUCCESS_ICON} npm-check installed successfully."
    else
      echo "${WARNING_ICON} Failed to install npm-check. Please install it manually with 'npm install -g npm-check'."
      echo "${ERROR_ICON} This script requires npm-check to function properly."
      exit 1
    fi
  else
    echo "${INFO_ICON} npm-check is already installed."
  fi
}

# Build exclude pattern for grep
build_exclude_pattern() {
  local pattern=""
  
  if [[ ${#EXCLUDE_MODULES[@]} -gt 0 ]]; then
    pattern=$(printf "|%s" "${EXCLUDE_MODULES[@]}")
    pattern=${pattern:1}  # Remove leading |
  fi
  
  echo $pattern
}

# Get list of modules to update
get_modules_to_update() {
  local exclude_pattern=$(build_exclude_pattern)
  local result_modules=()
  
  export NPM="$HOMEBREW_PREFIX/lib/node_modules"
  
  if [[ -z $exclude_pattern ]]; then
    result_modules=($(ls -lh $NPM | grep drwx | awk '{print $NF}' | grep -v "^@"))
  else
    result_modules=($(ls -lh $NPM | grep drwx | awk '{print $NF}' | grep -v "^@" | grep -Ev "$exclude_pattern"))
  fi
  
  # Add scoped packages (those starting with @)
  for scope in $(ls -lh $NPM | grep drwx | awk '{print $NF}' | grep "^@"); do
    if [[ -z $exclude_pattern ]]; then
      local scope_modules=($(ls -lh $NPM/$scope | grep drwx | awk '{print $NF}' | sed "s|^|$scope/|"))
    else
      local scope_modules=($(ls -lh $NPM/$scope | grep drwx | awk '{print $NF}' | sed "s|^|$scope/|" | grep -Ev "$exclude_pattern"))
    fi
    result_modules+=($scope_modules)
  done
  
  echo "${result_modules[@]}"
}

# Update npm globally
update_npm_global() {
  echo "${UPDATE_ICON} Updating NPM Global..."
  
  if [[ $DRY_RUN == true ]]; then
    echo "${INFO_ICON} Dry run: Would update npm globally"
    return
  fi
  
  # Get list of all global packages except corepack
  local global_packages
  if ! global_packages=$(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[] | select(. != "corepack")' 2>/dev/null); then
    echo "${WARNING_ICON} Failed to get list of global packages"
    return 1
  fi
  
  # Check if there are any packages to update
  if [[ -z "$global_packages" ]]; then
    echo "${SUCCESS_ICON} No global packages to update (excluding corepack)"
    return 0
  fi
  
  # Update each package individually using npm-check
  echo "${INFO_ICON} Updating global packages individually (excluding corepack)"
  local update_count=0
  local fail_count=0
  
  for pkg in $global_packages; do
    echo "${PACKAGE_ICON} Checking ${pkg}..."
    
    # Always use -y, --skip-unused, and --major flags to avoid prompts and update only major versions
    local cmd="npm-check -g -u -y --skip-unused --major $pkg"
    
    # Use a subshell to prevent npm-check from causing the script to exit
    (eval $cmd)
    if [[ $? -eq 0 ]]; then
      ((update_count++))
    else
      echo "${WARNING_ICON} Failed to update ${pkg} with npm-check"
      ((fail_count++))
    fi
  done
  
  if [[ $update_count -gt 0 ]]; then
    echo "${SUCCESS_ICON} Updated $update_count global packages with npm-check (excluding corepack)"
  else
    echo "${INFO_ICON} No packages were updated"
  fi
  
  return 0
}

# Update a specific module
update_module() {
  local module=$1
  
  echo "${PACKAGE_ICON} Updating $module..."
  
  if [[ $DRY_RUN == true ]]; then
    echo "${INFO_ICON} Dry run: Would update $module"
    return 0
  fi
  
  export NPM="$HOMEBREW_PREFIX/lib/node_modules"
  
  # Create a temporary directory for npm-check operations
  local tmp_dir=$(mktemp -d)
  local current_dir=$(pwd)
  
  # Change to the temporary directory
  cd "$tmp_dir" || {
    echo "${WARNING_ICON} Could not create temporary directory for npm-check operations"
    return 1
  }
  
  # Change to the module directory
  if cd "$NPM/$module"; then
    # Always use -y, --skip-unused, and --major flags to avoid prompts and update only major versions
    local cmd="npm-check -u -y --skip-unused --major"
    
    # Run npm-check with error handling
    { eval $cmd ; } > /dev/null 2>&1 || true
    
    if [[ $? -eq 0 ]]; then
      echo "${SUCCESS_ICON} $module updated successfully"
      cd "$tmp_dir"
      rm -rf "$tmp_dir"
      return 0
    else
      echo "${WARNING_ICON} Failed to update $module"
      cd "$tmp_dir"
      rm -rf "$tmp_dir"
      return 1
    fi
  else
    echo "${WARNING_ICON} Could not change to directory: $NPM/$module"
    rm -rf "$tmp_dir"
    return 1
  fi
}

# Main function
main() {
  check_dependencies
  
  export NPM="$HOMEBREW_PREFIX/lib/node_modules"
  
  # Show configuration
  echo "${CONFIG_ICON} Configuration:"
  echo "${NODE_ICON} NPM modules directory: $NPM"
  echo "${PACKAGE_ICON} Excluded modules: ${EXCLUDE_MODULES[@]:-None}"
  echo "${INFO_ICON} Dry run: $DRY_RUN"
  echo "${INFO_ICON} Global only: $GLOBAL_ONLY"
  echo
  
  # Get modules to update
  echo "${INFO_ICON} Getting module list..."
  local node_modules=($(get_modules_to_update))
  
  # Show what will be updated
  echo "${PACKAGE_ICON} Modules to update (${#node_modules[@]}):"
  if [[ $VERBOSE == true ]]; then
    printf "  %s\n" "${node_modules[@]}"
  else
    # Show first few modules
    if [[ ${#node_modules[@]} -gt 0 ]]; then
      local preview="${node_modules[1]}"
      if [[ ${#node_modules[@]} -gt 1 ]]; then
        preview="$preview, ${node_modules[2]}"
      fi
      if [[ ${#node_modules[@]} -gt 2 ]]; then
        preview="$preview, ... (use --verbose to see all)"
      fi
      echo "  $preview"
    fi
  fi
  echo
  
  # Update npm globally
  update_npm_global
  
  # Update each module
  local success_count=0
  local fail_count=0
  
  if [[ $GLOBAL_ONLY != true ]]; then
    for module in "${node_modules[@]}"; do
      echo
      if update_module "$module"; then
        ((success_count++))
      else
        ((fail_count++))
      fi
    done
  else
    echo "${INFO_ICON} Skipping individual modules (--global-only specified)"
  fi
  
  # Summary
  echo
  echo "${INFO_ICON} Update Summary:"
  echo "${SUCCESS_ICON} Successfully updated: $success_count modules"
  if [[ $fail_count -gt 0 ]]; then
    echo "${WARNING_ICON} Failed to update: $fail_count modules"
  fi
  echo "${NODE_ICON} Total modules processed: ${#node_modules[@]}"
}

# Run the main function
main "$@"
