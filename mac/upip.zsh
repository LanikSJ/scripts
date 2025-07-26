#!/usr/bin/env zsh
# This script will update all the Python modules

# Icons for better visual output
INFO_ICON="ℹ️ "
SUCCESS_ICON="✅ "
WARNING_ICON="⚠️ "
ERROR_ICON="❌ "
PACKAGE_ICON="📦 "
PYTHON_ICON="🐍 "
UPDATE_ICON="🔄 "
CONFIG_ICON="⚙️ "

# Default configuration
typeset -a EXCLUDE_PACKAGES=("types-setuptools")
typeset -a PYTHON_VERSIONS=("python3.13")
VERBOSE=false
DRY_RUN=false

# Help function
show_help() {
  cat << EOF
${PYTHON_ICON} $(basename $0) - Python Package Updater

Usage: $(basename $0) [options]

Options:
  -h, --help           Show this help message and exit
  -e, --exclude LIST   Comma-separated list of packages to exclude from updates
  -p, --python LIST    Comma-separated list of Python versions to update (default: python3.12,python3.13)
  -v, --verbose        Enable verbose output
  -d, --dry-run        Show what would be updated without making changes
  -y, --yes            Skip confirmation prompt

Example:
  $(basename $0) --exclude "types-setuptools,pytest" --python "python3.11,python3.12"
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
      IFS=',' read -A EXCLUDE_PACKAGES <<< "$2"
      shift 2
      ;;
    -p|--python)
      IFS=',' read -A PYTHON_VERSIONS <<< "$2"
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
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check dependencies
check_dependencies() {
  if ! command -v jq &> /dev/null; then
    echo "${ERROR_ICON} Error: jq is not installed. Please install it first."
    echo "  brew install jq"
    exit 1
  fi
}

# Check if Python version exists
check_python_version() {
  local python_version=$1
  if ! command -v $python_version &> /dev/null; then
    echo "${WARNING_ICON} Warning: $python_version not found, skipping..."
    return 1
  fi
  return 0
}

# Build exclude pattern for grep
build_exclude_pattern() {
  local pattern=""
  
  if [[ ${#EXCLUDE_PACKAGES[@]} -gt 0 ]]; then
    pattern=$(printf "|%s" "${EXCLUDE_PACKAGES[@]}")
    pattern=${pattern:1}  # Remove leading |
  fi
  
  echo $pattern
}

# Get list of packages to update
get_packages_to_update() {
  local python_version=$1
  local exclude_pattern=$(build_exclude_pattern)
  
  if [[ -z $exclude_pattern ]]; then
    $python_version -m pip list --format=json | jq -r '.[].name'
  else
    $python_version -m pip list --format=json | jq -r '.[].name' | grep -Ev "$exclude_pattern"
  fi
}

# Update Python modules
update_python_modules() {
  local python_version=$1
  local packages=()
  local exclude_pattern=$(build_exclude_pattern)
  
  echo "${INFO_ICON} Getting package list for $python_version..."
  
  # Get list of packages to update
  if [[ -z $exclude_pattern ]]; then
    packages=($($python_version -m pip list --format=json | jq -r '.[].name'))
  else
    packages=($($python_version -m pip list --format=json | jq -r '.[].name' | grep -Ev "$exclude_pattern"))
  fi
  
  # Show what will be updated
  echo "${PACKAGE_ICON} Packages to update (${#packages[@]}):"
  if [[ $VERBOSE == true ]]; then
    printf "  %s\n" "${packages[@]}"
  else
    echo "  ${packages[1]}, ${packages[2]}, ... (use --verbose to see all)"
  fi
  
  # Exit if dry run
  if [[ $DRY_RUN == true ]]; then
    return
  fi
  
  # Update packages in a single command for better performance
  if [[ ${#packages[@]} -gt 0 ]]; then
    echo "${UPDATE_ICON} Updating packages for $python_version..."
    $python_version -m pip install -U ${packages[@]}
  else
    echo "${INFO_ICON} No packages to update for $python_version."
  fi
}

# Main function
main() {
  check_dependencies
  
  # Show configuration
  echo "${CONFIG_ICON} Configuration:"
  echo "${PYTHON_ICON} Python versions: ${PYTHON_VERSIONS[@]}"
  echo "${PACKAGE_ICON} Excluded packages: ${EXCLUDE_PACKAGES[@]}"
  echo "${INFO_ICON} Dry run: $DRY_RUN"
  echo
  
  # Confirm before proceeding
  if [[ $SKIP_CONFIRM != true && $DRY_RUN != true ]]; then
    echo -n "${INFO_ICON} Do you want to continue? [y/N] "
    read -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
      echo "${WARNING_ICON} Operation cancelled."
      exit 0
    fi
  fi
  
  # Update packages for each Python version
  for python_version in "${PYTHON_VERSIONS[@]}"; do
    echo
    echo "${PYTHON_ICON} Processing $python_version..."
    
    if check_python_version $python_version; then
      update_python_modules $python_version
    fi
  done
  
  echo
  echo "${SUCCESS_ICON} All Python packages have been processed."
}

# Run the main function
main
