#!/usr/bin/env bash
#
# hostname.sh - Check and set hostname based on the machine's serial number
#
# This script retrieves the Mac's serial number and sets the hostname to match it
# if not already set. It requires root privileges to set the hostname.

# Icons
SERIAL_ICON="🔢"
COMPUTER_ICON="💻"
SUCCESS_ICON="✅"
ERROR_ICON="❌"
INFO_ICON="ℹ️"

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Variables
serial_number=$(ioreg -l | grep IOPlatformSerialNumber | awk '{print $NF}' | sed 's/"//g')

# Check if serial number was retrieved successfully
if [[ -z "${serial_number}" ]]; then
  echo "${ERROR_ICON} Error: Could not retrieve serial number." >&2
  exit 1
fi

# Functions
display_hostname() {
  # Display current hostname settings
  echo
  echo "${COMPUTER_ICON} ComputerName: $(scutil --get ComputerName 2>/dev/null || echo "Not set")"
  echo "${COMPUTER_ICON} LocalHostName: $(scutil --get LocalHostName 2>/dev/null || echo "Not set")"
  echo "${COMPUTER_ICON} HostName: $(scutil --get HostName 2>/dev/null || echo "Not set")"
}

set_hostname() {
  # Set hostname to the provided serial number
  # Requires root privileges
  if [[ "${EUID}" -ne 0 ]]; then
    echo "${ERROR_ICON} This script must be run with sudo to set hostname." >&2
    exit 1
  fi
  
  echo "${INFO_ICON} Setting hostname to: ${serial_number}"
  scutil --set ComputerName "${serial_number}" || echo "${ERROR_ICON} Failed to set ComputerName" >&2
  scutil --set LocalHostName "${serial_number}" || echo "${ERROR_ICON} Failed to set LocalHostName" >&2
  scutil --set HostName "${serial_number}" || echo "${ERROR_ICON} Failed to set HostName" >&2
}

check_hostname() {
  # Check if any of the hostname settings match the serial number
  local computer_name
  local local_hostname
  local hostname
  
  computer_name=$(scutil --get ComputerName 2>/dev/null || echo "")
  local_hostname=$(scutil --get LocalHostName 2>/dev/null || echo "")
  hostname=$(scutil --get HostName 2>/dev/null || echo "")
  
  if [[ "${computer_name}" == "${serial_number}" ]] || 
     [[ "${local_hostname}" == "${serial_number}" ]] || 
     [[ "${hostname}" == "${serial_number}" ]]; then
    return 0  # At least one hostname matches the serial number
  else
    return 1  # No hostname matches the serial number
  fi
}

main() {
  # Main function to control script flow
  echo "${SERIAL_ICON} Serial Number: ${serial_number}"
  
  if check_hostname; then
    echo "${SUCCESS_ICON} Hostname already set to serial number!"
    display_hostname
  else
    echo "${INFO_ICON} Hostname does not match serial number."
    display_hostname
    echo
    echo "${INFO_ICON} To set hostname to serial number, run this script with sudo."
    
    # Only attempt to set hostname if running with sudo
    if [[ "${EUID}" -eq 0 ]]; then
      echo
      set_hostname
      echo "${SUCCESS_ICON} Hostname updated successfully!"
      display_hostname
    fi
  fi
}

# Execute main function
main
