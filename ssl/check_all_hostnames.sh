#!/bin/bash
# Script to check SSL certificate expiry for all hostnames in hostnames.txt
# Also checks VPN connection and mc status for eagle and merlin

# Define colors and icons for output formatting
GREEN='\033[92m'
YELLOW='\033[93m'
RED='\033[91m'
BLUE='\033[94m'
RESET='\033[0m'
INFO='ℹ'
SUCCESS='✓'
WARNING='⚠'
ERROR='✗'

# Function to check if VPN is connected
check_vpn_connection() {
    echo -e "${BLUE}${INFO}${RESET} Checking VPN connection..."
    
    # This is a generic check that looks for common VPN interfaces
    # Modify this based on your specific VPN software/configuration
    if ifconfig | grep -q -E 'tun|tap|ppp|vpn'; then
        echo -e "${GREEN}${SUCCESS} VPN is connected${RESET}"
        return 0
    else
        echo -e "${RED}${ERROR} VPN is not connected${RESET}"
        return 1
    fi
}

# Function to check mctunnel status for eagle and merlin
check_mc_status() {
    echo -e "${BLUE}${INFO}${RESET} Checking mctunnel status for eagle and merlin..."
    
    # Run mctunnel status command and capture output
    mc_output=$(mctunnel status 2>&1)
    
    # Display the mc status output
    echo "$mc_output"
    
    # Check if eagle status is OK
    if echo "$mc_output" | grep -q "eagle.*OK"; then
        echo -e "${GREEN}${SUCCESS} eagle is connected${RESET}"
        eagle_connected=true
    else
        echo -e "${RED}${ERROR} eagle is not connected${RESET}"
        eagle_connected=false
    fi
    
    # Check if merlin status is OK
    if echo "$mc_output" | grep -q "merlin.*OK"; then
        echo -e "${GREEN}${SUCCESS} merlin is connected${RESET}"
        merlin_connected=true
    else
        echo -e "${RED}${ERROR} merlin is not connected${RESET}"
        merlin_connected=false
    fi
    
    # Return success only if both are connected
    if $eagle_connected && $merlin_connected; then
        return 0
    else
        return 1
    fi
}

# Path to the Python script
SSL_CHECK_SCRIPT="$HOME/bin/ssl/check_ssl_expiry.py"
HOSTNAMES_FILE="$HOME/Drive-Gov/SSL/hostnames.txt"

# Check VPN connection first
check_vpn_connection
vpn_status=$?

# Check mc status for eagle and merlin
check_mc_status
mc_status=$?

# If VPN is not connected or mc status check failed, ask user if they want to continue
if [ $vpn_status -ne 0 ] || [ $mc_status -ne 0 ]; then
    echo -e "${YELLOW}${WARNING} Warning: VPN connection or mc status check failed${RESET}"
    read -p "Do you want to continue with SSL certificate checks anyway? (y/n): " continue_choice
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}${INFO}${RESET} Exiting as requested."
        exit 1
    fi
    echo "----------------------------------------"
fi

# Check if the Python script exists
if [ ! -f "$SSL_CHECK_SCRIPT" ]; then
    echo -e "${RED}${ERROR} Error: SSL check script not found at $SSL_CHECK_SCRIPT${RESET}"
    exit 1
fi

# Check if the hostnames file exists
if [ ! -f "$HOSTNAMES_FILE" ]; then
    echo -e "${RED}${ERROR} Error: Hostnames file not found at $HOSTNAMES_FILE${RESET}"
    exit 1
fi

# Make the Python script executable if it's not already
chmod +x "$SSL_CHECK_SCRIPT"

echo -e "${BLUE}${INFO}${RESET} Starting SSL certificate expiry check for all hostnames..."
echo -e "${BLUE}${INFO}${RESET} Using hostnames from: $HOSTNAMES_FILE"
echo -e "${BLUE}${INFO}${RESET} Using SSL check script: $SSL_CHECK_SCRIPT"
echo "----------------------------------------"

# Initialize counters and arrays
total=0
valid=0
warning=0
expired=0
error=0
expiring_soon=()
expiring_30days=0

# Read each hostname from the file and check SSL expiry
while IFS= read -r hostname || [ -n "$hostname" ]; do
    # Skip empty lines
    if [ -z "$hostname" ]; then
        continue
    fi
    
    ((total++))
    echo -e "${BLUE}${INFO}${RESET} Checking: $hostname"
    
    # Run the Python script for the current hostname
    output=$("$SSL_CHECK_SCRIPT" "$hostname" 2>&1)
    exit_code=$?
    
    # Display the output
    echo "$output"
    
    # Check if certificate is expiring in 30 days or less
    if echo "$output" | grep -q -E "expires in ([1-9]|[12][0-9]|30) days"; then
        expiring_soon+=("$hostname: $(echo "$output" | grep -E "expires in ([1-9]|[12][0-9]|30) days")")
        ((expiring_30days++))
    fi
    
    # Update counters based on exit code
    case $exit_code in
        0) ((valid++)) ;;
        1) ((warning++)) ;;
        2) ((expired++)) ;;
        *) ((error++)) ;;
    esac
    
    echo "----------------------------------------"
done < "$HOSTNAMES_FILE"

# Display summary
echo -e "${BLUE}${INFO}${RESET} SSL Certificate Check Summary:"
echo -e "${GREEN}${SUCCESS} Valid:${RESET} $valid"
echo -e "${YELLOW}${WARNING} Warning:${RESET} $warning"
echo -e "${YELLOW}${WARNING} Expiring in 30 days:${RESET} $expiring_30days"
echo -e "${RED}${ERROR} Expired:${RESET} $expired"
echo -e "${RED}${ERROR} Errors:${RESET} $error"
echo -e "${BLUE}${INFO}${RESET} Total hostnames checked: $total"

# Display domains expiring in 30 days or less
if [ ${#expiring_soon[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}${WARNING}${RESET} Domains expiring in 30 days or less:"
    for domain in "${expiring_soon[@]}"; do
        echo -e "${YELLOW}  - $domain${RESET}"
    done
fi

# Exit with appropriate code
if [ $expired -gt 0 ]; then
    exit 2
elif [ $warning -gt 0 ] || [ $error -gt 0 ]; then
    exit 1
else
    exit 0
fi
