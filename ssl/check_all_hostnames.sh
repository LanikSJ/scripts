#!/bin/bash
# Script to check SSL certificate expiry for all hostnames in hostnames.txt

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

# Path to the Python script
SSL_CHECK_SCRIPT="$HOME/bin/ssl/check_ssl_expiry.py"
HOSTNAMES_FILE="$HOME/Drive-Gov/SSL/hostnames.txt"

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

# Initialize counters
total=0
valid=0
warning=0
expired=0
error=0

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
echo -e "${RED}${ERROR} Expired:${RESET} $expired"
echo -e "${RED}${ERROR} Errors:${RESET} $error"
echo -e "${BLUE}${INFO}${RESET} Total hostnames checked: $total"

# Exit with appropriate code
if [ $expired -gt 0 ]; then
    exit 2
elif [ $warning -gt 0 ] || [ $error -gt 0 ]; then
    exit 1
else
    exit 0
fi
