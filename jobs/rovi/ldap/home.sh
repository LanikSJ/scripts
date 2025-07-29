#!/usr/bin/env bash
#
# This script ensures correct user and group permissions for all user home directories.
# It iterates through system users and applies appropriate ownership and permissions
# to their home directories located under a specified base directory.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The exit status of a pipeline is the exit status of the last command.
set -o pipefail

# --- Configuration Variables ---
readonly HOME_BASE_DIR="/home"

# --- Helper Functions ---

# Function to print error messages to stderr
print_error() {
    printf "Error: %s\n" "$1" >&2
}

# Function to print warning messages to stderr
print_warning() {
    printf "Warning: %s\n" "$1" >&2
}

# --- Main Script Logic ---

printf "Starting to change user/group permissions on home directories under '%s'...\n" "${HOME_BASE_DIR}"

# Check if the home base directory exists
if [ ! -d "${HOME_BASE_DIR}" ]; then
    print_error "Home base directory '%s' does not exist. Exiting.\n" "${HOME_BASE_DIR}"
    exit 1
fi

# Iterate over actual users with home directories under HOME_BASE_DIR
# Using getent passwd to get a reliable list of users and their home directories
while IFS=: read -r username _uid _gid _gecos home_dir _shell; do
    # Check if the home directory exists and is under the HOME_BASE_DIR
    if [[ "${home_dir}" == "${HOME_BASE_DIR}/"* && -d "${home_dir}" ]]; then
        printf "Processing home directory for user '%s' at '%s'...\n" "${username}" "${home_dir}"

        # Change user ownership
        if chown -R "${username}" "${home_dir}"; then
            printf "  User ownership for '%s' set successfully.\n" "${username}"
        else
            print_error "Failed to change user ownership for '%s' on '%s'.\n" "${username}" "${home_dir}"
        fi

        # Change group ownership
        # Get the primary group name for the user
        groupname=$(id -gn "${username}" 2>/dev/null)
        if [ -n "${groupname}" ]; then
            if chgrp -R "${groupname}" "${home_dir}"; then
                printf "  Group ownership for '%s' set successfully.\n" "${username}"
            else
                print_error "Failed to change group ownership for '%s' on '%s'.\n" "${groupname}" "${home_dir}"
            fi
        else
            print_warning "Could not determine primary group for user '%s'. Skipping group ownership change.\n" "${username}"
        fi

        # Set directory permissions (e.g., 700 for user rwx, no access for group/others)
        if chmod 700 "${home_dir}"; then
            printf "  Permissions for '%s' set to 700 successfully.\n" "${username}"
        else
            print_error "Failed to set permissions for '%s' on '%s'.\n" "${username}" "${home_dir}"
        fi
    fi
done < <(getent passwd)

printf "\nAll specified home directory permissions have been processed.\n"
