#!/usr/bin/env bash
#
# Network Interface Restart Script
# 
# This script identifies all active network interfaces and restarts them.
# It requires sudo privileges to bring interfaces down and up.
# Based on: https://apple.stackexchange.com/questions/191879/how-to-find-the-currently-connected-network-service-from-the-command-line
#

set -e  # Exit immediately if a command exits with a non-zero status

# Check if script is run with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo privileges to restart network interfaces."
   echo "Please run: sudo $0"
   exit 1
fi

# Function to restart a network interface
restart_interface() {
    local device="$1"
    
    echo "Restarting $device..."
    /sbin/ifconfig "$device" down || { echo "Failed to bring $device down"; return 1; }
    /sbin/ifconfig "$device" up || { echo "Failed to bring $device up"; return 1; }
    echo "Done!"
    return 0
}

# Main function to find and restart active interfaces
restart_active_interfaces() {
    local active_interfaces_found=0
    
    while read -r line; do
        # Extract device from the line
        local device
        device=$(echo "$line" | awk -F  "(, )|(: )|[)]" '{print $4}')
        
        # Skip if device is empty
        [[ -z "$device" ]] && continue
        
        # Check if interface is active
        if ifconfig "$device" 2>/dev/null | grep -q 'status: active'; then
            active_interfaces_found=1
            
            echo # Print a blank line for readability
            restart_interface "$device"
        fi
    done <<< "$(networksetup -listnetworkserviceorder | grep 'Hardware Port')"
    
    # Check if any active interfaces were found
    if [[ $active_interfaces_found -eq 0 ]]; then
        echo "Could not find current service"
        return 1
    fi
    
    return 0
}

# Execute the main function
restart_active_interfaces
exit_code=$?

exit $exit_code
