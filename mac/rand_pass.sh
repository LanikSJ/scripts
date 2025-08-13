#!/usr/bin/env bash
# Random password generator with improved security and cleanup features

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
DEFAULT_LENGTH=20
SCRIPT_NAME="Password Generator"
LOG_DIR="/tmp/rand_pass_logs"
ICON="🔐"

# Function to display status with icon
show_status() {
    local message="$1"
    local icon="${2:-ℹ️}"
    echo "${icon} ${message}"
}

# Function to cleanup temporary files and logs
cleanup_logs() {
    if [[ -d "$LOG_DIR" ]]; then
        rm -rf "$LOG_DIR" 2>/dev/null || true
        show_status "Cleaned up temporary log files" "🧹"
    fi
}

# Function to generate secure password
generate_password() {
    local length="${1:-$DEFAULT_LENGTH}"
    
    # Validate length
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
        show_status "Error: Length must be a positive integer" "❌"
        exit 1
    fi
    
    # Check if openssl is available
    if ! command -v openssl >/dev/null 2>&1; then
        show_status "Error: openssl is required but not installed" "❌"
        exit 1
    fi
    
    # Create log directory for any temporary operations
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    
    # Generate cryptographically secure password
    # Use base64 and clean up non-alphanumeric characters (more secure than MD5)
    local password
    password=$(openssl rand -base64 $((length * 2)) | tr -d "=+/" | tr -d '\n' | head -c"$length")
    
    # Ensure we have the exact length requested
    while [ ${#password} -lt "$length" ]; do
        local additional
        additional=$(openssl rand -base64 10 | tr -d "=+/" | tr -d '\n')
        password="${password}${additional}"
    done
    
    # Trim to exact length
    password=${password:0:$length}
    
    echo "$password"
}

# Main execution
main() {
    local length="${1:-$DEFAULT_LENGTH}"
    
    show_status "Generating secure ${length}-character password..." "$ICON"
    
    # Generate the password
    local password
    password=$(generate_password "$length")
    
    # Display the password
    echo "$password"
    
    # Cleanup on successful completion
    cleanup_logs
    show_status "Password generated successfully!" "✅"
}

# Handle script arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    echo "${ICON} ${SCRIPT_NAME}"
    echo "Usage: $0 [length]"
    echo "  length: Password length (default: $DEFAULT_LENGTH)"
    echo "Example: $0 16"
    exit 0
fi

# Run main function with all arguments
main "$@"
