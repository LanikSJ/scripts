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
typeset -a EXCLUDE_PACKAGES=()
typeset -a PYTHON_VERSIONS=()  # Will be auto-detected if not specified
VERBOSE=true
DRY_RUN=false
AUTO_DETECT=true  # Auto-detect Python versions by default

# Help function
show_help() {
  local script_name="upip.zsh"
  cat << EOF
${PYTHON_ICON} $script_name - Python Package Updater

Usage: $script_name [options]

Options:
  -h, --help           Show this help message and exit
  -e, --exclude LIST   Comma-separated list of packages to exclude from updates
  -p, --python LIST    Comma-separated list of Python versions to update (auto-detected by default)
  -v, --verbose        Enable verbose output
  -d, --dry-run        Show what would be updated without making changes

Example:
  $script_name --exclude "types-setuptools,pytest" --python "python3.11,python3.12"
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
      AUTO_DETECT=false  # Disable auto-detection when specific versions are provided
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

# Detect installed Python versions
detect_python_versions() {
  echo "${INFO_ICON} Auto-detecting Python versions..." >&2
  local detected_versions=()
  
  # Check for python3
  if command -v python3 &> /dev/null; then
    detected_versions+=("python3")
  fi
  
  # Check for specific Python 3 versions (3.7 through 3.14)
  for version in {7..14}; do
    if command -v "python3.$version" &> /dev/null; then
      detected_versions+=("python3.$version")
    fi
  done
  
  # If no Python versions found, warn the user
  if [[ ${#detected_versions[@]} -eq 0 ]]; then
    echo "${WARNING_ICON} No Python versions detected on this system." >&2
    return 1
  fi
  
  echo "${SUCCESS_ICON} Detected Python versions: ${detected_versions[@]}" >&2
  
  # Return the detected versions as a space-separated string
  local output=""
  for version in "${detected_versions[@]}"; do
    output+="$version "
  done
  echo -n "${output% }"  # Remove trailing space
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
  
  # Update pip itself first
  echo "${UPDATE_ICON} Updating pip for $python_version..."
  $python_version -m pip install -U pip

  # Update packages in a single command for better performance
  if [[ ${#packages[@]} -gt 0 ]]; then
    echo "${UPDATE_ICON} Updating packages for $python_version..."
    $python_version -m pip install -U -v ${packages[@]}
  else
    echo "${INFO_ICON} No packages to update for $python_version."
  fi
}

# Main function
main() {
  check_dependencies
  
  # Auto-detect Python versions if enabled
  if [[ $AUTO_DETECT == true ]]; then
    # Capture the output of detect_python_versions into an array
    IFS=' ' read -A PYTHON_VERSIONS <<< "$(detect_python_versions)"
    
    # If no Python versions were detected, exit
    if [[ ${#PYTHON_VERSIONS[@]} -eq 0 ]]; then
      echo "${ERROR_ICON} No Python versions found. Please install Python or specify versions manually."
      exit 1
    fi
  fi
  
  # Show configuration
  echo "${CONFIG_ICON} Configuration:"
  echo "${PYTHON_ICON} Python versions: ${PYTHON_VERSIONS[@]}"
  echo "${PACKAGE_ICON} Excluded packages: ${EXCLUDE_PACKAGES[@]}"
  echo "${INFO_ICON} Dry run: $DRY_RUN"
  echo
  
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
