#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status.
set -euo pipefail

INSTALLER_PATH="/var/www/store.ws.trygames.com/installer"
BACKUP_PATH="/var/www/store.ws.trygames.com/installer_orig"
ALERT_RECIPIENTS="noc-alerts@macrovision.com,dep-publish@macrovision.com"
ALERT_SUBJECT="$(hostname) installer"

echo "--- Installer Health Check and Restoration ---"

# 1. Ensure a backup of the installer exists
if [ ! -d "${BACKUP_PATH}" ]; then
    echo "Backup directory '${BACKUP_PATH}' does not exist. Creating a backup from '${INSTALLER_PATH}'..."
    if cp -rp "${INSTALLER_PATH}" "${BACKUP_PATH}"; then
        echo "Backup created successfully."
    else
        echo "Error: Failed to create backup. Exiting." >&2
        exit 1
    fi
else
    echo "Backup directory '${BACKUP_PATH}' already exists. Proceeding."
fi

# 2. Check if the installer is present and restore if missing
if [ -d "${INSTALLER_PATH}" ]; then
    echo "Installer directory '${INSTALLER_PATH}' is present. No action needed."
else
    echo "Installer directory '${INSTALLER_PATH}' is missing. Attempting to restore from backup..."
    if cp -rp "${BACKUP_PATH}" "${INSTALLER_PATH}"; then
        echo "Installer restored successfully from backup."
        echo "It seems that the installer has been deleted. I have restored it. ;-)" | mail -s "${ALERT_SUBJECT}" "${ALERT_RECIPIENTS}"
        echo "Notification email sent."
    else
        echo "Error: Failed to restore installer from backup. Manual intervention may be required." >&2
        exit 1
    fi
fi

echo "--- Script finished ---"
