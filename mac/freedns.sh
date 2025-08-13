#!/usr/bin/env bash

# FreeDNS Dynamic DNS Update Script
# Updates DNS records via FreeDNS service
# Author: LanikSJ
# Version: 2.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "$0")"
readonly FREEDNS_URL="http://sync.afraid.org/u/jmbh7WvKkGuMRwdxWVcfEqce/"
readonly LOG_FILE="${HOME}/.local/log/freedns.log"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
readonly TIMEOUT=30
readonly MAX_RETRIES=3

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function with icons
log() {
    local level="$1"
    shift
    local icon=""
    
    case "$level" in
        "INFO")  icon="ℹ️ " ;;
        "WARN")  icon="⚠️ " ;;
        "ERROR") icon="❌" ;;
        "DEBUG") icon="🔍" ;;
        "SUCCESS") icon="✅" ;;
    esac
    
    echo "${icon} [$level] $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Check if script is already running
if [[ -f "$LOCK_FILE" ]]; then
    if kill -0 "$(cat "$LOCK_FILE")" 2>/dev/null; then
        error_exit "Script is already running (PID: $(cat "$LOCK_FILE"))"
    else
        log "WARN" "Removing stale lock file"
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Check for required commands
command -v curl >/dev/null 2>&1 || error_exit "curl is not installed"

# Validate URL format
if [[ ! "$FREEDNS_URL" =~ ^https?:// ]]; then
    error_exit "Invalid URL format: $FREEDNS_URL"
fi

# Function to update DNS
update_dns() {
    local attempt=1
    local response
    local http_code
    
    log "INFO" "Starting FreeDNS update"
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "INFO" "Attempt $attempt of $MAX_RETRIES"
        
        # Use HTTPS if available, fallback to HTTP
        local url="$FREEDNS_URL"
        if [[ "$url" == http://* ]]; then
            local https_url="${url/http:/https:}"
            if curl -s --connect-timeout 5 --max-time 10 "$https_url" >/dev/null 2>&1; then
                url="$https_url"
                log "INFO" "Using HTTPS connection"
            else
                log "WARN" "HTTPS not available, using HTTP"
            fi
        fi
        
        # Perform the update with proper error handling
        if response=$(curl -s \
            --connect-timeout "$TIMEOUT" \
            --max-time "$TIMEOUT" \
            --user-agent "FreeDNS-Updater/2.0" \
            --write-out "HTTPSTATUS:%{http_code}" \
            "$url" 2>&1); then
            
            # Extract HTTP status code
            http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
            response=${response%HTTPSTATUS:*}
            
            case "$http_code" in
                200)
                    log "SUCCESS" "DNS update successful"
                    [[ -n "$response" ]] && log "DEBUG" "Response: $response"
                    return 0
                    ;;
                4[0-9][0-9])
                    error_exit "Client error (HTTP $http_code): Check your FreeDNS URL"
                    ;;
                5[0-9][0-9])
                    log "WARN" "Server error (HTTP $http_code), retrying..."
                    ;;
                *)
                    log "WARN" "Unexpected HTTP status: $http_code"
                    ;;
            esac
        else
            log "WARN" "curl failed: $response"
        fi
        
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            local wait_time=$((attempt * 5))
            log "INFO" "Waiting ${wait_time}s before retry..."
            sleep "$wait_time"
        fi
        
        ((attempt++))
    done
    
    error_exit "Failed to update DNS after $MAX_RETRIES attempts"
}

# Function to check internet connectivity
check_connectivity() {
    log "INFO" "Checking internet connectivity"
    
    local test_hosts=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
            log "SUCCESS" "Internet connectivity confirmed"
            return 0
        fi
    done
    
    error_exit "No internet connectivity detected"
}

# Main execution
main() {
    log "INFO" "FreeDNS update script started"
    
    # Check connectivity first
    check_connectivity
    
    # Update DNS
    update_dns
    
    log "SUCCESS" "FreeDNS update completed successfully"
    
    # Clean up log file on successful completion
    if [[ -f "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE"
        echo "✅ [SUCCESS] Log file cleaned up after successful run"
    fi
}

# Show usage information
usage() {
    cat << EOF
🌐 FreeDNS Dynamic DNS Update Script

📋 Usage: $SCRIPT_NAME [OPTIONS]

⚙️  OPTIONS:
    -h, --help      📖 Show this help message
    -v, --verbose   🔍 Enable verbose logging
    -d, --dry-run   🧪 Show what would be done without executing

💡 EXAMPLES:
    $SCRIPT_NAME                    # ▶️  Normal execution
    $SCRIPT_NAME --verbose          # 🔍 Verbose output
    $SCRIPT_NAME --dry-run          # 🧪 Test mode

📁 LOG FILE: $LOG_FILE
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            set -x  # Enable debug output
            shift
            ;;
        -d|--dry-run)
            echo "🧪 DRY RUN MODE - No actual DNS update will be performed"
            echo "🌐 Would update: $FREEDNS_URL"
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main
