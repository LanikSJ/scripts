#!/usr/bin/env bash

# macOS "Open With" Menu Cleanup Script
# This script cleans up duplicate and invalid entries in the "Open With" context menu
# by rebuilding the Launch Services database and restarting the Dock.

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Script metadata
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Icons for output
readonly ICON_INFO="ℹ️"
readonly ICON_SUCCESS="✅"
readonly ICON_WARNING="⚠️"
readonly ICON_ERROR="❌"
readonly ICON_CLEANUP="🧹"
readonly ICON_ROCKET="🚀"
readonly ICON_GEAR="⚙️"

# Log file paths
readonly LOG_DIR="$HOME/.cache/openwith-cleanup"
readonly LOG_FILE="$LOG_DIR/cleanup.log"
readonly ERROR_LOG="$LOG_DIR/error.log"

# Logging functions
log_info() {
    echo -e "${BLUE}${ICON_INFO} [INFO]${NC} $1"
    [[ -d "$LOG_DIR" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}${ICON_SUCCESS} [SUCCESS]${NC} $1"
    [[ -d "$LOG_DIR" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}${ICON_WARNING} [WARNING]${NC} $1"
    [[ -d "$LOG_DIR" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}${ICON_ERROR} [ERROR]${NC} $1" >&2
    [[ -d "$LOG_DIR" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
}

# Initialize logging
init_logging() {
    if [[ "${QUIET_MODE:-false}" == "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Open With cleanup session" > "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error log initialized" > "$ERROR_LOG"
    fi
}

# Clean up log files on successful completion
cleanup_logs() {
    if [[ -d "$LOG_DIR" ]]; then
        log_info "${ICON_CLEANUP} Cleaning up log files..."
        rm -rf "$LOG_DIR"
        echo -e "${GREEN}${ICON_SUCCESS} [SUCCESS]${NC} Log files cleaned up successfully"
    fi
}

# Display usage information
show_usage() {
    cat << EOF
${ICON_GEAR} Usage: $SCRIPT_NAME [OPTIONS]

Clean up macOS "Open With" menu by rebuilding Launch Services database.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    -q, --quiet     Run in quiet mode (minimal output)
    -y, --yes       Skip confirmation prompt
    --keep-logs     Keep log files after successful completion

DESCRIPTION:
    This script performs the following actions:
    1. ${ICON_CLEANUP} Rebuilds the Launch Services database
    2. ${ICON_ROCKET} Restarts the Dock to apply changes
    3. ${ICON_SUCCESS} Cleans up temporary log files (unless --keep-logs is used)
    
    This resolves issues with:
    • Duplicate entries in "Open With" menus
    • Invalid or broken application associations
    • Outdated file type associations

EXAMPLES:
    $SCRIPT_NAME              # Interactive mode with confirmation
    $SCRIPT_NAME -y           # Run without confirmation
    $SCRIPT_NAME -q -y        # Run quietly without confirmation
    $SCRIPT_NAME --keep-logs  # Keep log files after completion

EOF
}

# Show version information
show_version() {
    echo "${ICON_GEAR} $SCRIPT_NAME version $SCRIPT_VERSION"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi
}

# Check if lsregister exists and is executable
check_lsregister() {
    local lsregister_path="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    
    if [[ ! -x "$lsregister_path" ]]; then
        log_error "lsregister not found or not executable at: $lsregister_path"
        log_error "This may indicate a system integrity issue or unsupported macOS version."
        exit 1
    fi
}

# Confirm action with user
confirm_action() {
    if [[ "${SKIP_CONFIRMATION:-false}" == "true" ]]; then
        return 0
    fi
    
    echo
    log_warning "This will rebuild the Launch Services database and restart the Dock."
    log_warning "All Dock customizations will be reset to defaults."
    echo
    read -p "${ICON_INFO} Do you want to continue? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user."
        exit 0
    fi
}

# Perform the cleanup
cleanup_open_with() {
    local lsregister_path="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    
    log_info "${ICON_GEAR} Starting Launch Services database cleanup..."
    
    # Rebuild Launch Services database
    if ! "$lsregister_path" -kill -r -all local,system,user 2>/dev/null; then
        log_error "Failed to rebuild Launch Services database."
        log_error "You may need to run this script with administrator privileges."
        exit 1
    fi
    
    log_success "Launch Services database rebuilt successfully."
    
    # Restart Dock
    log_info "${ICON_ROCKET} Restarting Dock..."
    if ! killall Dock 2>/dev/null; then
        log_warning "Failed to restart Dock automatically. Please restart it manually."
        log_info "You can restart the Dock by running: killall Dock"
    else
        log_success "Dock restarted successfully."
    fi
}

# Main function
main() {
    local quiet_mode=false
    local keep_logs=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -q|--quiet)
                quiet_mode=true
                QUIET_MODE=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --keep-logs)
                keep_logs=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information."
                exit 1
                ;;
        esac
    done
    
    # Initialize logging
    init_logging
    
    # Redirect output if in quiet mode
    if [[ "$quiet_mode" == "true" ]]; then
        exec > /dev/null
    fi
    
    # Perform checks
    check_macos
    check_lsregister
    
    # Show script information
    if [[ "$quiet_mode" == "false" ]]; then
        echo
        log_info "${ICON_CLEANUP} macOS Open With Menu Cleanup Script v$SCRIPT_VERSION"
        echo
    fi
    
    # Confirm action
    confirm_action
    
    # Perform cleanup
    cleanup_open_with
    
    # Success message
    if [[ "$quiet_mode" == "false" ]]; then
        echo
        log_success "${ICON_SUCCESS} Open With menu cleanup completed successfully!"
        log_info "${ICON_INFO} The changes should be visible immediately in context menus."
        echo
    fi
    
    # Clean up log files unless --keep-logs is specified
    if [[ "$keep_logs" == "false" && "$quiet_mode" == "false" ]]; then
        cleanup_logs
    elif [[ "$keep_logs" == "true" ]]; then
        log_info "${ICON_INFO} Log files preserved at: $LOG_DIR"
    fi
}

# Run main function with all arguments
main "$@"
