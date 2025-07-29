#!/usr/bin/env bash
#
# This script copies a set of LDAP-related configuration files to a specified destination.
# It ensures that the script exits on error and provides informative messages.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u

# Define the source files to be copied
readonly SOURCE_FILES=(
    "/etc/issue.old"
    "/etc/ssh/sshd_config"
    "/etc/mail/sendmail.cf"
    "/etc/mail/ldap"
    "/etc/aliases"
    "/etc/openldap/cacerts/f114b579.0"
    "/etc/ldap.conf"
    "/etc/nsswitch.conf"
    "/etc/pam.d/system-auth"
    "/etc/security/access.conf"
    "/etc/resolv.conf"
)

# Define the destination directory
readonly DESTINATION_DIR="/var/linux/redhat/misc/5Server/templates/ldap"

# Check if the destination directory exists, create it if not
if [ ! -d "${DESTINATION_DIR}" ]; then
    printf "Destination directory '%s' does not exist. Creating it...\n" "${DESTINATION_DIR}"
    mkdir -p "${DESTINATION_DIR}" || { printf "Error: Failed to create destination directory '%s'.\n" "${DESTINATION_DIR}" >&2; exit 1; }
fi

printf "Starting to copy LDAP configuration files to '%s'...\n" "${DESTINATION_DIR}"

# Iterate over each source file and copy it
for file in "${SOURCE_FILES[@]}"; do
    if [ -f "${file}" ]; then
        printf "Copying '%s'...\n" "${file}"
        cp -f "${file}" "${DESTINATION_DIR}/" || { printf "Error: Failed to copy '%s'.\n" "${file}" >&2; exit 1; }
    else
        printf "Warning: Source file '%s' not found. Skipping.\n" "${file}" >&2
    fi
done

printf "All specified LDAP configuration files have been processed.\n"
