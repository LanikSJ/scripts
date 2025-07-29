#!/usr/bin/env bash
#
# This script renames a specific user's home directory and then
# ensures correct user and group permissions for all home directories.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The exit status of a pipeline is the exit status of the last command.
set -o pipefail

# --- Configuration Variables ---
readonly HOME_BASE_DIR="/home"
readonly OLD_USERNAME="rayc"
readonly NEW_USERNAME="rcasaclang"

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

printf "Checking if '%s' directory contains home directories...\n" "${HOME_BASE_DIR}"

# Check if the home base directory is empty
if [ -z "$(ls -A "${HOME_BASE_DIR}")" ]; then
    printf "'%s' is empty. No home directories to process.\n" "${HOME_BASE_DIR}"
    exit 0
else
    printf "Home directories located in '%s'.\n" "${HOME_BASE_DIR}"
fi

# --- Rename Ray Casaclang's home directory ---
printf "\nAttempting to rename home directory for '%s' to '%s'...\n" "${OLD_USERNAME}" "${NEW_USERNAME}"
if [ -d "${HOME_BASE_DIR}/${OLD_USERNAME}" ]; then
    mv -f "${HOME_BASE_DIR}/${OLD_USERNAME}" "${HOME_BASE_DIR}/${NEW_USERNAME}"
    printf "Successfully renamed '%s' to '%s'.\n" "${OLD_USERNAME}" "${NEW_USERNAME}"
else
    print_warning "Home directory for '${OLD_USERNAME}' (${HOME_BASE_DIR}/${OLD_USERNAME}) does not exist. Skipping rename.\n"
fi

# --- Change user/group permissions on home directories ---
printf "\nChanging user/group permissions on home directories under '%s'...\n" "${HOME_BASE_DIR}"

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

        # Set directory permissions (e.g., 750 for user rwx, group rx, others no access)
        if chmod 750 "${home_dir}"; then
            printf "  Permissions for '%s' set to 750 successfully.\n" "${username}"
        else
            print_error "Failed to set permissions for '%s' on '%s'.\n" "${username}" "${home_dir}"
        fi
    fi
done < <(getent passwd)

printf "\nAll specified home directory permissions have been processed.\n"
