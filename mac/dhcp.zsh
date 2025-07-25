#!/usr/bin/env zsh
#
# Script: dhcp.zsh
# Description: Renews DHCP leases and DNS settings for network interfaces
# Usage: sudo ./dhcp.zsh
#

# Exit on error
set -e

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo privileges"
   echo "Usage: sudo $0"
   exit 1
fi

# Function to get interface name
get_interface_name() {
    local search_string="$1"
    networksetup -listnetworkserviceorder | grep -A1 "$search_string" | grep -i hardware | awk '{print $NF}' | sed 's/)//'
}

# Function to check if interface is active
is_interface_active() {
    local interface="$1"
    
    # Skip if interface is empty
    if [[ -z "$interface" ]]; then
        return 1
    fi
    
    # Check interface status using ifconfig (macOS native command)
    if ifconfig "$interface" 2>/dev/null | grep -q "status: active"; then
        return 0
    else
        return 1
    fi
}

# Function to renew DHCP lease
renew_dhcp() {
    local interface="$1"
    local interface_type="$2"
    
    echo "Renewing DHCP lease for $interface_type interface ($interface)..."
    if ipconfig set "$interface" DHCP; then
        echo "✅ $interface_type Connection Reset Successfully!"
    else
        echo "❌ Failed to reset $interface_type connection"
        return 1
    fi
}

# Main script execution
echo "🔄 Checking network interfaces..."

# Get interface names
WIRED_INTERFACE=$(get_interface_name "USB 10/100/1000 LAN")
WIRELESS_INTERFACE=$(get_interface_name "Wi-Fi")

# Process wired connection
if [[ -n "$WIRED_INTERFACE" ]]; then
    if is_interface_active "$WIRED_INTERFACE"; then
        renew_dhcp "$WIRED_INTERFACE" "Wired"
    else
        echo "❗ No active wired connection detected on interface $WIRED_INTERFACE"
    fi
else
    echo "❗ No wired interface found"
fi

# Process wireless connection
if [[ -n "$WIRELESS_INTERFACE" ]]; then
    if is_interface_active "$WIRELESS_INTERFACE"; then
        renew_dhcp "$WIRELESS_INTERFACE" "Wireless"
    else
        echo "❗ No active wireless connection detected on interface $WIRELESS_INTERFACE"
    fi
else
    echo "❗ No wireless interface found"
fi

echo "🔄 DHCP renewal process completed"
