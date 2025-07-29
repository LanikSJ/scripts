#!/usr/bin/env bash
#
# This script applies LDAP configuration fixes based on the server's network
# location (Tulsa Armus) and Red Hat Enterprise Linux (RHEL) version.
# It retrieves configuration files and restarts necessary services.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The exit status of a pipeline is the exit status of the last command.
set -o pipefail

# --- Configuration Variables ---
readonly RESOLV_CONF_FILE="/etc/resolv.conf"
readonly TULSA_ARMUS_IPS=("10.202.0.11" "10.202.0.12")

# --- Helper Functions ---

# Function to print error messages to stderr and exit
print_error_and_exit() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

# Function to check if a service command exists and execute it
restart_service() {
    local service_name="$1"
    printf "Restarting service '%s'...\n" "${service_name}"
    if command -v systemctl &> /dev/null; then
        systemctl restart "${service_name}" || print_error_and_exit "Failed to restart service '${service_name}' using systemctl."
    elif command -v service &> /dev/null; then
        service "${service_name}" restart || print_error_and_exit "Failed to restart service '${service_name}' using service command."
    else
        print_error_and_exit "Neither 'systemctl' nor 'service' command found. Cannot restart '${service_name}'."
    fi
}

# --- Main Script Logic ---

# Check if the machine is in Tulsa Armus by looking for specific IPs in resolv.conf
printf "Checking if this machine is in Tulsa Armus...\n"
local_armus_check=0
if [ -f "${RESOLV_CONF_FILE}" ]; then
    for ip in "${TULSA_ARMUS_IPS[@]}"; do
        if grep -q "${ip}" "${RESOLV_CONF_FILE}"; then
            local_armus_check=1
            break
        fi
    done
else
    print_error_and_exit "Cannot find ${RESOLV_CONF_FILE}. Unable to determine network location."
fi

if [ "${local_armus_check}" -eq 0 ]; then
    printf "This machine is not in Tulsa Armus. Exiting.\n"
    exit 0 # Exit gracefully if not in the target environment
fi

printf "Machine is in Tulsa Armus. Proceeding with LDAP fix.\n"

# Determine RHEL version
# Using 'rpm -q' for redhat-release packages to identify RHEL version
# Initialize variables to empty strings to prevent unbound variable errors
RHEL_VERSION=""

if rpm -q --queryformat '%{VERSION}' redhat-release &> /dev/null; then
    RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release)
elif rpm -q --queryformat '%{VERSION}' redhat-release-server &> /dev/null; then
    RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release-server)
fi

if [ -z "${RHEL_VERSION}" ]; then
    print_error_and_exit "Could not determine RHEL version. Exiting."
fi

printf "Detected RHEL version: %s\n" "${RHEL_VERSION}"

# Apply fixes based on RHEL version
if [ "${RHEL_VERSION}" = "5Server" ]; then
    printf "Applying fixes for RHEL 5 Server...\n"
    if command -v rhncfg-client &> /dev/null; then
        rhncfg-client get /etc/ldap.conf || print_error_and_exit "Failed to get /etc/ldap.conf using rhncfg-client."
    else
        print_error_and_exit "'rhncfg-client' command not found. Cannot retrieve /etc/ldap.conf."
    fi
    restart_service "nscd"
elif [ "${RHEL_VERSION}" = "6Server" ]; then
    printf "Applying fixes for RHEL 6 Server...\n"
    if command -v rhncfg-client &> /dev/null; then
        rhncfg-client get /etc/ldap.conf /etc/nslcd.conf || print_error_and_exit "Failed to get LDAP configuration files using rhncfg-client."
    else
        print_error_and_exit "'rhncfg-client' command not found. Cannot retrieve LDAP configuration files."
    fi
    restart_service "nscd"
    restart_service "nslcd"
else
    printf "This is not a recognized RHEL 5 or 6 Server (%s). Exiting.\n" "${RHEL_VERSION}"
    exit 0 # Exit gracefully if not a target RHEL version
fi

printf "LDAP fix script completed successfully.\n"
