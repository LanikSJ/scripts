#!/usr/bin/env bash
#
# This script synchronizes files to the Cacti Development Box.
# It ensures the script only runs on the designated host and provides progress updates.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u

# Define the expected hostname for the Cacti Development Box
readonly EXPECTED_HOST="sjc1itdcacti1"
# Define the path to the rsync exclusion file
readonly EXCLUSIONS_FILE="/home/ierenstein/scripts/cacti/exclusions.txt"
# Define the source directory for rsync
readonly SOURCE_DIR="/home/ierenstein/"
# Define the destination for rsync
readonly DESTINATION="ierenstein@cacti:/home/ierenstein/"

# Get the current hostname
CURRENT_HOST=$(hostname -s)

# Check if the current host matches the expected Cacti Dev Box
if [ "${CURRENT_HOST}" != "${EXPECTED_HOST}" ]; then
    printf "Error: This script is intended to run only on the Cacti Development Box (%s).\n" "${EXPECTED_HOST}" >&2
    exit 1
else
    printf "\nScript started on -- %s.\n" "$(date)"

    # Execute rsync command with specified options
    # -a: archive mode (preserves permissions, ownership, timestamps, etc.)
    # -v: verbose output
    # --progress: show progress during transfer
    # --delete: delete extraneous files from dest dir (not in source)
    # --exclude-from: exclude files listed in the specified file
    rsync -av --progress --delete --exclude-from="${EXCLUSIONS_FILE}" "${SOURCE_DIR}" "${DESTINATION}"
fi
