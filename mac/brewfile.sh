#!/usr/bin/env bash

# Brewfile Generator Script
# Creates a Brewfile that can be used to install all currently installed brew packages
# Usage: ./brewfile.sh [OPTIONS]

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Default values
BREWFILE_PATH="${HOME}/.Brewfile"
BACKUP_EXISTING=true
VERBOSE=false
SHOW_HELP=false
BACKUP_PATH=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Creates a Brewfile containing all currently installed Homebrew packages.

OPTIONS:
    -f, --file PATH     Specify output file path (default: ~/.Brewfile)
    -n, --no-backup     Don't backup existing Brewfile
    -v, --verbose       Enable verbose output
    -h, --help          Show this help message

EXAMPLES:
    $(basename "$0")                    # Create ~/.Brewfile with backup
    $(basename "$0") -f ./Brewfile      # Create Brewfile in current directory
    $(basename "$0") -n -v              # No backup, verbose output

EOF
}

# Function to log messages
log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}ℹ️  [INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ [SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  [WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}❌ [ERROR]${NC} $message" >&2
            ;;
        "VERBOSE")
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${BLUE}🔍 [VERBOSE]${NC} $message"
            fi
            ;;
    esac
}

# Function to check if Homebrew is installed
check_brew_installed() {
    if ! command -v brew &> /dev/null; then
        log "ERROR" "🍺 Homebrew is not installed or not in PATH"
        log "INFO" "📥 Install Homebrew from: https://brew.sh"
        exit 1
    fi
    
    log "VERBOSE" "🍺 Homebrew found at: $(command -v brew)"
}

# Function to backup existing Brewfile
backup_brewfile() {
    if [[ -f "$BREWFILE_PATH" && "$BACKUP_EXISTING" == true ]]; then
        BACKUP_PATH="${BREWFILE_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$BREWFILE_PATH" "$BACKUP_PATH"
        log "INFO" "💾 Existing Brewfile backed up to: $BACKUP_PATH"
    fi
}

# Function to validate output directory
validate_output_path() {
    local output_dir
    output_dir="$(dirname "$BREWFILE_PATH")"
    
    if [[ ! -d "$output_dir" ]]; then
        log "ERROR" "📁 Output directory does not exist: $output_dir"
        exit 1
    fi
    
    if [[ ! -w "$output_dir" ]]; then
        log "ERROR" "🔒 No write permission for directory: $output_dir"
        exit 1
    fi
    
    log "VERBOSE" "📁 Output directory validated: $output_dir"
}

# Function to generate Brewfile
generate_brewfile() {
    log "INFO" "🍺 Generating Brewfile at: $BREWFILE_PATH"
    
    # Count packages before generation for reporting
    local formula_count cask_count tap_count
    formula_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    tap_count=$(brew tap 2>/dev/null | wc -l | tr -d ' ')
    
    log "VERBOSE" "📦 Found $formula_count formulae, $cask_count casks, and $tap_count taps"
    
    # Generate the Brewfile
    if brew bundle dump --all --force --file="$BREWFILE_PATH"; then
        log "SUCCESS" "🍺 Brewfile created successfully"
        log "INFO" "📦 Included: $formula_count formulae, $cask_count casks, $tap_count taps"
        
        # Show file size
        if command -v stat &> /dev/null; then
            local file_size
            if [[ "$OSTYPE" == "darwin"* ]]; then
                file_size=$(stat -f%z "$BREWFILE_PATH")
            else
                file_size=$(stat -c%s "$BREWFILE_PATH")
            fi
            log "VERBOSE" "📏 Brewfile size: $file_size bytes"
        fi
    else
        log "ERROR" "🍺 Failed to generate Brewfile"
        exit 1
    fi
}

# Function to show Brewfile preview
show_preview() {
    if [[ -f "$BREWFILE_PATH" && "$VERBOSE" == true ]]; then
        log "VERBOSE" "👀 Brewfile contents preview (first 10 lines):"
        head -10 "$BREWFILE_PATH" | sed 's/^/  /'
        
        local line_count
        line_count=$(wc -l < "$BREWFILE_PATH")
        if [[ $line_count -gt 10 ]]; then
            log "VERBOSE" "📄 ... and $((line_count - 10)) more lines"
        fi
    fi
}

# Function to cleanup backup file after successful completion
cleanup_backup() {
    if [[ -n "$BACKUP_PATH" && -f "$BACKUP_PATH" ]]; then
        rm "$BACKUP_PATH"
        log "INFO" "🗑️  Backup file cleaned up: $BACKUP_PATH"
        log "VERBOSE" "🧹 Temporary backup removed after successful generation"
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                BREWFILE_PATH="$2"
                shift 2
                ;;
            -n|--no-backup)
                BACKUP_EXISTING=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                SHOW_HELP=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_arguments "$@"
    
    if [[ "$SHOW_HELP" == true ]]; then
        show_usage
        exit 0
    fi
    
    log "INFO" "🚀 Starting Brewfile generation..."
    
    check_brew_installed
    validate_output_path
    backup_brewfile
    generate_brewfile
    show_preview
    cleanup_backup
    
    log "SUCCESS" "🎉 Brewfile generation completed!"
    log "INFO" "🔄 To restore packages on another system, run: brew bundle install --file=\"$BREWFILE_PATH\""
}

# Run main function with all arguments
main "$@"
