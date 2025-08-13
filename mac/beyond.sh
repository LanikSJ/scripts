#!/usr/bin/env bash

# Beyond Compare Registry Reset Script
# Purpose: Removes Beyond Compare registry file and launches the application
# This is typically used to reset Beyond Compare's trial period or configuration

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration
readonly SCRIPT_NAME
SCRIPT_NAME="$(basename "$0")"
readonly BC_REGISTRY_PATH="$HOME/Library/Application Support/Beyond Compare/registry.dat"
readonly BC_APP_PATH="/Applications/Beyond Compare.app"
readonly BC_UTILITIES_PATH="/Applications/Utilities/Beyond Compare.app"

# Logging functions with icons
log_info() {
    echo "ℹ️  [INFO] $*" >&2
}

log_error() {
    echo "❌ [ERROR] $*" >&2
}

log_warning() {
    echo "⚠️  [WARNING] $*" >&2
}

log_success() {
    echo "✅ [SUCCESS] $*" >&2
}

# Function to display usage information
usage() {
    cat << EOF
🔧 Beyond Compare Registry Reset Tool

Usage: $SCRIPT_NAME [OPTIONS]

Reset Beyond Compare registry and launch the application.

OPTIONS:
    -h, --help      📖 Show this help message
    -n, --no-launch 🚫 Don't launch Beyond Compare after registry reset
    -v, --verbose   🔍 Enable verbose output

DESCRIPTION:
    This script removes the Beyond Compare registry file and optionally
    launches the application. This is commonly used to reset trial periods
    or configuration issues.

EXAMPLES:
    $SCRIPT_NAME                    # 🔄 Reset registry and launch app
    $SCRIPT_NAME --no-launch        # 🗑️  Only reset registry
    $SCRIPT_NAME --verbose          # 📝 Show detailed output

EOF
}

# Function to check if Beyond Compare is running
is_bc_running() {
    pgrep -f "Beyond Compare" > /dev/null 2>&1
}

# Function to find Beyond Compare application
find_bc_app() {
    local app_path=""
    
    # Check common locations
    if [[ -d "$BC_APP_PATH" ]]; then
        app_path="$BC_APP_PATH"
    elif [[ -d "$BC_UTILITIES_PATH" ]]; then
        app_path="$BC_UTILITIES_PATH"
    else
        # Try to find it using spotlight
        app_path=$(mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == 'Beyond Compare'" | head -n1)
    fi
    
    echo "$app_path"
}

# Function to remove registry file
remove_registry() {
    local verbose="$1"
    
    if [[ -f "$BC_REGISTRY_PATH" ]]; then
        if [[ "$verbose" == "true" ]]; then
            log_info "🗑️  Removing registry file: $BC_REGISTRY_PATH"
        fi
        
        if rm -f "$BC_REGISTRY_PATH"; then
            log_success "Registry file removed successfully"
        else
            log_error "Failed to remove registry file"
            return 1
        fi
    else
        if [[ "$verbose" == "true" ]]; then
            log_info "🔍 Registry file not found: $BC_REGISTRY_PATH"
        fi
    fi
}

# Function to launch Beyond Compare
launch_bc() {
    local app_path="$1"
    local verbose="$2"
    
    if [[ -z "$app_path" ]]; then
        log_error "🔍 Beyond Compare application not found"
        log_error "📍 Please ensure Beyond Compare is installed in one of these locations:"
        log_error "   📁 $BC_APP_PATH"
        log_error "   📁 $BC_UTILITIES_PATH"
        return 1
    fi
    
    if [[ "$verbose" == "true" ]]; then
        log_info "🚀 Launching Beyond Compare from: $app_path"
    fi
    
    if open "$app_path"; then
        log_success "🚀 Beyond Compare launched successfully"
    else
        log_error "💥 Failed to launch Beyond Compare"
        return 1
    fi
}

# Main function
main() {
    local launch_app=true
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--no-launch)
                launch_app=false
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "🍎 This script is designed for macOS only"
        exit 1
    fi
    
    # Warn if Beyond Compare is currently running
    if is_bc_running; then
        log_warning "🏃 Beyond Compare appears to be running"
        log_warning "💡 Please quit the application before running this script for best results"
        read -p "❓ Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "🛑 Operation cancelled"
            exit 0
        fi
    fi
    
    # Remove registry file
    if ! remove_registry "$verbose"; then
        exit 1
    fi
    
    # Launch application if requested
    if [[ "$launch_app" == "true" ]]; then
        local app_path
        app_path=$(find_bc_app)
        
        if ! launch_bc "$app_path" "$verbose"; then
            exit 1
        fi
    fi
    
    log_success "🎉 Operation completed successfully"
}

# Run main function with all arguments
main "$@"
