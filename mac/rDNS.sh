#!/usr/bin/env bash

# DNS Cache Flush Script for macOS
# Description: Flushes DNS cache and restarts mDNS responder service
# Author: LanikSJ
# Version: 2.0
# Compatible: macOS 10.10+ (Yosemite and later)

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script configuration
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="${HOME}/Library/Logs/dns_flush.log"

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to print verbose output
print_verbose() {
    local message="$1"
    if [[ "${verbose:-false}" == true ]]; then
        print_status "$BLUE" "🔍 VERBOSE: $message"
    fi
}

# Function to log messages
log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "$LOG_FILE"
}

# Function to check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_status "$RED" "❌ Error: This script is designed for macOS only."
        exit 1
    fi
}

# Function to check if running with appropriate privileges
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_status "$YELLOW" "⚠️  Warning: Running as root. Consider running as regular user with sudo."
    fi
}

# Function to get macOS version
get_macos_version() {
    sw_vers -productVersion | cut -d. -f1,2
}

# Function to flush DNS cache based on macOS version
flush_dns_cache() {
    local macos_version
    macos_version=$(get_macos_version)
    
    print_status "$BLUE" "🖥️  Detected macOS version: $macos_version"
    print_verbose "Using macOS version-specific DNS flush command"
    log_message "Flushing DNS cache on macOS $macos_version"
    
    # Different commands for different macOS versions
    case "$macos_version" in
        "10.10"|"10.11"|"10.12")
            # Yosemite, El Capitan, Sierra
            print_verbose "Using dscacheutil for macOS $macos_version"
            if ! sudo dscacheutil -flushcache; then
                print_status "$RED" "❌ Error: Failed to flush DNS cache with dscacheutil"
                return 1
            fi
            ;;
        *)
            # High Sierra and later (10.13+)
            print_verbose "Using dscacheutil for macOS $macos_version (High Sierra+)"
            if ! sudo dscacheutil -flushcache; then
                print_status "$RED" "❌ Error: Failed to flush DNS cache with dscacheutil"
                return 1
            fi
            ;;
    esac
    
    print_status "$GREEN" "✅ DNS cache flushed successfully"
    return 0
}

# Function to restart mDNS responder
restart_mdns_responder() {
    print_status "$BLUE" "🔄 Restarting mDNS responder..."
    print_verbose "Sending HUP signal to mDNSResponder process"
    log_message "Restarting mDNS responder"
    
    if ! sudo killall -HUP mDNSResponder 2>/dev/null; then
        print_status "$YELLOW" "⚠️  Warning: mDNSResponder may not be running or restart failed"
        print_verbose "killall command failed - mDNSResponder process may not exist"
        log_message "Warning: mDNSResponder restart failed or service not running"
        return 1
    fi
    
    print_status "$GREEN" "✅ mDNS responder restarted successfully"
    return 0
}

# Function to verify DNS functionality
verify_dns() {
    print_status "$BLUE" "🔍 Verifying DNS functionality..."
    print_verbose "Testing DNS resolution with google.com"
    
    # Test DNS resolution with a reliable domain
    if nslookup google.com >/dev/null 2>&1; then
        print_status "$GREEN" "✅ DNS resolution test passed"
        print_verbose "nslookup command succeeded"
        return 0
    else
        print_status "$YELLOW" "⚠️  Warning: DNS resolution test failed - network may be unavailable"
        print_verbose "nslookup command failed - check network connectivity"
        return 1
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

DNS Cache Flush Script for macOS

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -q, --quiet     Suppress non-error output
    --no-verify     Skip DNS verification test

EXAMPLES:
    $SCRIPT_NAME                    # Standard DNS flush
    $SCRIPT_NAME --verbose          # Verbose output
    $SCRIPT_NAME --quiet            # Quiet mode
    $SCRIPT_NAME --no-verify        # Skip verification

EOF
}

# Function to create log directory if it doesn't exist
setup_logging() {
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
}

# Function to clean up log files on successful completion
cleanup_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        print_verbose "Cleaning up log file: $LOG_FILE"
        rm -f "$LOG_FILE"
        print_verbose "Log file cleaned up successfully"
    fi
}

# Main function
main() {
    # Make verbose available globally for print_verbose function
    verbose=false
    local quiet=false
    local verify=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            --no-verify)
                verify=false
                shift
                ;;
            *)
                print_status "$RED" "❌ Error: Unknown option '$1'"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set quiet mode if requested
    if [[ "$quiet" == true ]]; then
        exec 1>/dev/null
    fi
    
    # Setup logging
    setup_logging
    
    print_status "$BLUE" "🚀 Starting DNS cache flush process..."
    print_verbose "Script version: 2.0"
    print_verbose "Log file location: $LOG_FILE"
    log_message "DNS flush script started by user: $(whoami)"
    
    # Perform checks
    print_verbose "Performing system compatibility checks"
    check_macos
    check_privileges
    
    # Main operations
    local exit_code=0
    
    if ! flush_dns_cache; then
        exit_code=1
    fi
    
    if ! restart_mdns_responder; then
        exit_code=1
    fi
    
    # Optional DNS verification
    if [[ "$verify" == true ]]; then
        if ! verify_dns; then
            print_status "$YELLOW" "⚠️  Note: DNS verification failed, but cache flush completed"
        fi
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        print_status "$GREEN" "🎉 DNS cache flush completed successfully!"
        print_verbose "All operations completed without errors"
        log_message "DNS flush completed successfully"
        
        # Clean up log files on successful completion
        cleanup_logs
    else
        print_status "$RED" "❌ DNS cache flush completed with warnings/errors"
        print_verbose "Some operations failed or produced warnings"
        log_message "DNS flush completed with errors"
        print_status "$BLUE" "📋 Check log file for details: $LOG_FILE"
    fi
    
    return $exit_code
}

# Trap to handle script interruption
trap 'print_status "$RED" "🛑 Script interrupted"; log_message "Script interrupted by user"; exit 130' INT TERM

# Run main function with all arguments
main "$@"
