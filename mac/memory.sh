#!/usr/bin/env bash
# shellcheck disable=SC2004

# Set strict error handling
set -euo pipefail

# Define icons for better visual output
readonly ICON_FREE="🟢"
readonly ICON_INACTIVE="🟡"
readonly ICON_TOTAL="📊"
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"

# Function to clean up any temporary or log files on successful completion
cleanup_logs() {
    local cleanup_patterns=(
        "/tmp/memory_*.log"
        "/tmp/vm_stat_*.tmp"
        "*.log"
        ".memory_cache"
    )
    
    for pattern in "${cleanup_patterns[@]}"; do
        # Use find to safely remove matching files
        find . -maxdepth 1 -name "${pattern##*/}" -type f -delete 2>/dev/null || true
    done
}

# Function to handle errors and cleanup
error_handler() {
    echo "${ICON_ERROR} Script failed. Cleaning up..." >&2
    cleanup_logs
    exit 1
}

# Set up error trap
trap error_handler ERR

# Improved parsing with better error handling
get_vm_stat_value() {
    local pattern="$1"
    local value
    
    value=$(vm_stat | grep "$pattern" | awk '{ print $3 }' | sed 's/\.//')
    
    # Validate that we got a numeric value
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        echo "${ICON_ERROR} Failed to parse $pattern value" >&2
        return 1
    fi
    
    echo "$value"
}

# Main execution
main() {
    echo "📱 macOS Memory Status"
    echo "====================="
    
    # Get memory statistics with error handling
    FREE_BLOCKS=$(get_vm_stat_value "free")
    INACTIVE_BLOCKS=$(get_vm_stat_value "inactive")
    SPECULATIVE_BLOCKS=$(get_vm_stat_value "speculative")
    
    # Calculate memory in MB (4096 bytes per page, 1048576 bytes per MB)
    FREE=$(((FREE_BLOCKS + SPECULATIVE_BLOCKS) * 4096 / 1048576))
    INACTIVE=$((INACTIVE_BLOCKS * 4096 / 1048576))
    TOTAL=$((FREE + INACTIVE))
    
    # Display results with icons and improved formatting
    printf "%s %-12s %6d MB\n" "$ICON_FREE" "Free:" "$FREE"
    printf "%s %-12s %6d MB\n" "$ICON_INACTIVE" "Inactive:" "$INACTIVE"
    printf "%s %-12s %6d MB\n" "$ICON_TOTAL" "Total free:" "$TOTAL"
    
    # Clean up any log files on successful completion
    cleanup_logs
    
    echo "${ICON_SUCCESS} Memory check completed successfully"
}

# Run main function
main "$@"
