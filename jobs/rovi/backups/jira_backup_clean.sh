#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error.
set -u
# The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if all commands exit successfully.
set -o pipefail

# --- Configuration ---
readonly LOGS_DIR="/jira/jira/logs"
readonly BACKUP_DIR="/jira/backup"
readonly CORRUPTED_DIR="/jira/backup/corrupted/"
readonly DAYS_TO_KEEP=90

# --- Functions ---

# Function to remove old files
# Arguments:
#   $1: Directory to clean
#   $2: File pattern (e.g., "*.log", "*.zip")
#   $3: Description for logging
cleanup_old_files() {
    local dir="$1"
    local pattern="$2"
    local description="$3"

    echo "Removing old ${description} older than ${DAYS_TO_KEEP} days from ${dir}."
    # Use -delete for efficiency and to avoid issues with filenames containing spaces or special characters.
    # -print is removed as it's not strictly necessary for the script's logic and can be noisy.
    if ! find "${dir}" -name "${pattern}" -type f -mtime +"${DAYS_TO_KEEP}" -delete; then
        echo "Error: ${description} could not be removed from ${dir}." >&2
        exit 1
    fi
    echo "${description} cleanup complete."
}

# --- Main Script ---

# Remove corrupted folder if it exists
if [ -d "${CORRUPTED_DIR}" ]; then
    echo "Removing corrupted folder from ${BACKUP_DIR} if it exists."
    # Suppress output of rm command
    rm -rf "${CORRUPTED_DIR}" > /dev/null
    echo "Corrupted folder cleanup complete."
fi

# Clean up old backups
cleanup_old_files "${BACKUP_DIR}" "*.zip" "backups"

# Clean up old logs
cleanup_old_files "${LOGS_DIR}" "*.log" "logs"

echo "All cleanup operations completed successfully!"
