#!/usr/bin/env bash

# Script: recycle.sh
# Purpose: Clean up Windows recycle bin files, desktop.ini files, and log files from macOS
# Author: LanikSJ
# Usage: ./recycle.sh [--dry-run] [--verbose] [--help]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Default options
DRY_RUN=false
VERBOSE=false
SEARCH_PATH="$HOME"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

🧹 Clean up Windows recycle bin files, desktop.ini files, and log files from macOS.

OPTIONS:
    --dry-run       Show what would be deleted without actually deleting
    --verbose       Enable verbose output
    --help          Show this help message
    --path PATH     Specify custom search path (default: $HOME)

EXAMPLES:
    $0                         # Clean up files in home directory
    $0 --dry-run               # Preview what would be deleted
    $0 --verbose --dry-run     # Verbose preview
    $0 --path /Volumes/USB     # Clean specific path

EOF
}

# Function to log messages with icons
log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}" >&2
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}" >&2
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}" >&2
            ;;
        "CLEAN")
            echo -e "${GREEN}🧹 $message${NC}" >&2
            ;;
    esac
}

# Function to safely find and process files
find_and_process() {
    local pattern="$1"
    local description="$2"
    local icon="$3"
    local found_files=0
    local processed_files=0
    
    log "INFO" "Searching for $description..."
    
    # Use find with proper quoting and null termination for safety
    while IFS= read -r -d '' file; do
        ((found_files++))
        
        if [[ "$VERBOSE" == true ]]; then
            log "INFO" "Found: $file"
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "$icon Would delete: $file"
        else
            if rm -rf "$file" 2>/dev/null; then
                ((processed_files++))
                if [[ "$VERBOSE" == true ]]; then
                    log "SUCCESS" "Deleted: $file"
                fi
            else
                log "ERROR" "Failed to delete: $file"
            fi
        fi
    done < <(find "$SEARCH_PATH" -name "$pattern" -print0 2>/dev/null)
    
    if [[ "$found_files" -eq 0 ]]; then
        log "INFO" "No $description found"
    else
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "Found $found_files $description (dry run mode)"
        else
            log "SUCCESS" "Processed $processed_files of $found_files $description"
        fi
    fi
    
    return 0
}

# Function to clean up log files
cleanup_logs() {
    local log_patterns=("*.log" "*.out" "*.err" "nohup.out" ".DS_Store")
    
    for pattern in "${log_patterns[@]}"; do
        find_and_process "$pattern" "log files ($pattern)" "📝"
    done
}

# Function to validate search path
validate_path() {
    if [[ ! -d "$SEARCH_PATH" ]]; then
        log "ERROR" "Search path does not exist: $SEARCH_PATH"
        exit 1
    fi
    
    if [[ ! -r "$SEARCH_PATH" ]]; then
        log "ERROR" "Search path is not readable: $SEARCH_PATH"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        --path)
            if [[ -n "${2:-}" ]]; then
                SEARCH_PATH="$2"
                shift 2
            else
                log "ERROR" "--path requires a directory argument"
                exit 1
            fi
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log "CLEAN" "Starting cleanup process..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log "WARN" "DRY RUN MODE - No files will be deleted"
    fi
    
    log "INFO" "Search path: $SEARCH_PATH"
    
    # Validate search path
    validate_path
    
    # Process recycle bin files
    find_and_process "*RECYCLE*" "Windows recycle bin files" "🗑️ "
    
    # Process desktop.ini files
    find_and_process "desktop.ini" "desktop.ini files" "📄"
    
    # Clean up log files on successful completion
    if [[ "$DRY_RUN" == false ]]; then
        log "INFO" "Cleaning up log files..."
        cleanup_logs
    fi
    
    log "SUCCESS" "Cleanup process completed successfully! 🎉"
}

# Run main function
main "$@"
