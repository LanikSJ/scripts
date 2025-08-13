#!/usr/bin/env bash

# Improved pylint wrapper script with better practices
# Usage: ./pylint.sh [file_pattern] [pylint_path] [config_file]

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Script metadata
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "$0")"
# readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/pylint_${USER}_$$.log"

# Default configuration
readonly DEFAULT_FILE_PATTERN="*.py"
readonly DEFAULT_PYLINT_CMD="pylint"
readonly DEFAULT_CONFIG_FILE="$HOME/.pylintrc"

# Icons for better visual feedback
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️"
readonly ICON_INFO="ℹ️"
readonly ICON_SEARCH="🔍"
readonly ICON_CLEAN="🧹"

# Parse command line arguments with better defaults
FILES="${1:-$DEFAULT_FILE_PATTERN}"
PYLINT_PATH="${2:-$DEFAULT_PYLINT_CMD}"
CONFIG_FILE="${3:-$DEFAULT_CONFIG_FILE}"

# Function to display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [file_pattern] [pylint_path] [config_file]

Arguments:
    file_pattern    File pattern to search for (default: $DEFAULT_FILE_PATTERN)
    pylint_path     Path to pylint executable (default: $DEFAULT_PYLINT_CMD)
    config_file     Path to pylint config file (default: $DEFAULT_CONFIG_FILE)

Examples:
    $SCRIPT_NAME                           # Run on all *.py files
    $SCRIPT_NAME "test_*.py"              # Run on test files only
    $SCRIPT_NAME "*.py" "/path/to/pylint" # Use specific pylint path
    $SCRIPT_NAME "*.py" "pylint" "/path/to/config"  # Use custom config

EOF
}

# Function to log messages with timestamps and icons
log() {
    local level="${1:-INFO}"
    shift
    local icon=""
    
    case "$level" in
        SUCCESS) icon="$ICON_SUCCESS" ;;
        ERROR)   icon="$ICON_ERROR" ;;
        WARNING) icon="$ICON_WARNING" ;;
        INFO)    icon="$ICON_INFO" ;;
        SEARCH)  icon="$ICON_SEARCH" ;;
        CLEAN)   icon="$ICON_CLEAN" ;;
        *)       icon="$ICON_INFO" ;;
    esac
    
    local message
    message="$icon [$(date +'%Y-%m-%d %H:%M:%S')] $*"
    echo "$message" >&2
    echo "$message" >> "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to cleanup temporary files
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log CLEAN "Cleaning up log files after successful completion"
        [[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"
        log SUCCESS "Cleanup completed"
    else
        log WARNING "Script failed, keeping log file: $LOG_FILE"
    fi
    
    exit $exit_code
}

# Set up cleanup trap
trap cleanup EXIT

# Validate pylint is available
if ! command_exists "$PYLINT_PATH"; then
    log ERROR "pylint not found at '$PYLINT_PATH'"
    log ERROR "Please install pylint or provide correct path as second argument"
    exit 1
fi

# Check if config file exists (only if not using default pylint config)
if [[ "$CONFIG_FILE" != "$DEFAULT_CONFIG_FILE" ]] && [[ ! -f "$CONFIG_FILE" ]]; then
    log WARNING "Config file '$CONFIG_FILE' not found, using pylint defaults"
    CONFIG_ARGS=""
else
    CONFIG_ARGS="--rcfile=$CONFIG_FILE"
fi

# Modern pylint configuration (updated from old 1.6.4 settings)
# Disabled rules explanation:
# - missing-docstring (C0111): Allow missing docstrings for small scripts
# - import-error (E0401): Often false positives in virtual environments
# - redefined-outer-name (W0621): Common in test files and small scripts
# - too-many-locals (R0914): Sometimes necessary for complex functions
# - too-few-public-methods (R0903): Allow simple data classes
# shellcheck disable=SC2054
readonly PYLINT_ARGS=(
    --reports=n
    --score=n
    --disable=missing-docstring,import-error,redefined-outer-name,too-many-locals,too-few-public-methods
    "$CONFIG_ARGS"
)

# Function to run pylint on files
run_pylint() {
    local file_count=0
    local files_array=()
    
    log SEARCH "Searching for files matching pattern '$FILES'"
    
    # Use mapfile to safely handle filenames with spaces
    while IFS= read -r -d '' file; do
        files_array+=("$file")
        ((file_count++))
    done < <(find . -type f -name "$FILES" -print0)
    
    if [[ $file_count -eq 0 ]]; then
        log ERROR "No files matching pattern '$FILES' found"
        return 1
    fi
    
    log SUCCESS "Found $file_count file(s) matching pattern '$FILES'"
    log INFO "Running pylint with: $PYLINT_PATH ${PYLINT_ARGS[*]}"
    
    # Run pylint on all files at once for better performance
    if "$PYLINT_PATH" "${PYLINT_ARGS[@]}" "${files_array[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "Pylint analysis completed without errors"
        return 0
    else
        local pylint_exit_code=${PIPESTATUS[0]}
        if [[ $pylint_exit_code -eq 0 ]]; then
            log SUCCESS "Pylint analysis completed successfully"
            return 0
        else
            log ERROR "Pylint found issues (exit code: $pylint_exit_code)"
            return "$pylint_exit_code"
        fi
    fi
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Main execution
main() {
    log INFO "Starting pylint analysis..."
    log INFO "Log file: $LOG_FILE"
    
    if run_pylint; then
        log SUCCESS "Pylint analysis completed successfully"
        return 0
    else
        log ERROR "Pylint analysis failed or found issues"
        return 1
    fi
}

# Execute main function
main "$@"
