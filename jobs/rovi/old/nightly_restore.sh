#!/bin/bash
# This script downloads a PostgreSQL backup from a remote server,
# restores it to the local database, and cleans up temporary files.

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if all commands in the pipeline exit successfully.
set -euo pipefail

# --- Configuration ---
BACKUP_URL_BASE="https://backups.trymedia.com/databases/trygames"
WGET_USER="backups"
# It is highly recommended to use a .netrc file or environment variable for the password
# instead of hardcoding it directly in the script for security reasons.
# For example: export WGET_PASSWORD='your_password' in your environment or a secure config file.
WGET_PASSWORD="${WGET_PASSWORD:-'1w@ntb@ckup$'}" # Fallback to hardcoded if not set
PG_USER="postgres"
# It is highly recommended to use a .pgpass file or environment variable for the password
# instead of hardcoding it directly in the script for security reasons.
# For example: export PGPASSWORD='your_password' in your environment or a secure config file.
PG_PASSWORD="${PGPASSWORD:-}" # PGPASSWORD should be set in the environment for psql

# --- Calculate Date ---
# Use 'date -v-1d' for macOS/BSD compatibility. For GNU/Linux, use 'date --date='1 day ago''
TODAY=$(date -v-1d +%Y-%m-%d)
BACKUP_FILE_GZ="${TODAY}.pgbackup-master.gz"
BACKUP_FILE_UNZIPPED="${TODAY}.pgbackup-master"
TEMP_DIR="/tmp"
TEMP_BACKUP_PATH_GZ="${TEMP_DIR}/${BACKUP_FILE_GZ}"
TEMP_BACKUP_PATH_UNZIPPED="${TEMP_DIR}/${BACKUP_FILE_UNZIPPED}"

# --- Trap for cleanup on exit ---
cleanup() {
    echo "Cleaning up temporary files..."
    rm -f "${TEMP_BACKUP_PATH_GZ}" "${TEMP_BACKUP_PATH_UNZIPPED}"
    echo "Cleanup complete."
}
trap cleanup EXIT

echo "--- Starting Database Restore Process ---"

# --- Download Backup ---
echo "Downloading the backup: ${BACKUP_URL_BASE}/trygames/${BACKUP_FILE_GZ}"
wget "${BACKUP_URL_BASE}/trygames/${BACKUP_FILE_GZ}" \
    --http-user="${WGET_USER}" \
    --http-passwd="${WGET_PASSWORD}" \
    -O "${TEMP_BACKUP_PATH_GZ}"
echo "Backup downloaded successfully to ${TEMP_BACKUP_PATH_GZ}"

# --- Unzip Backup ---
echo "Unzipping the backup: ${TEMP_BACKUP_PATH_GZ}"
gunzip "${TEMP_BACKUP_PATH_GZ}"
echo "Backup unzipped successfully to ${TEMP_BACKUP_PATH_UNZIPPED}"

# --- Drop Databases (if they exist) ---
echo "Checking and dropping 'trygames' database if it exists..."
if psql -U "${PG_USER}" -d template1 -tAc "SELECT 1 FROM pg_database WHERE datname = 'trygames'" | grep -q 1; then
    echo "'trygames' database found. Dropping..."
    psql -U "${PG_USER}" -d template1 -c 'drop database trygames;'
    echo "'trygames' database dropped."
else
    echo "'trygames' database does not exist. Skipping drop."
fi

echo "Checking and dropping 'adserver' database if it exists..."
if psql -U "${PG_USER}" -d template1 -tAc "SELECT 1 FROM pg_database WHERE datname = 'adserver'" | grep -q 1; then
    echo "'adserver' database found. Dropping..."
    psql -U "${PG_USER}" -d template1 -c 'drop database adserver;'
    echo "'adserver' database dropped."
else
    echo "'adserver' database does not exist. Skipping drop."
fi

# --- Dump Backup into Database ---
echo "Dumping the backup into the database from ${TEMP_BACKUP_PATH_UNZIPPED}"
# Ensure PGPASSWORD is set in the environment for psql to use it
PGPASSWORD="${PG_PASSWORD}" psql -U "${PG_USER}" -d template1 < "${TEMP_BACKUP_PATH_UNZIPPED}"
echo "Backup dumped into the database successfully."

echo "--- Database Restore Process Complete ---"
