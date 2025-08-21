#!/usr/bin/env bash

DATE=$(date +"%Y%m%d-%H%M")
HOST='***REMOVED***'
USER='***REMOVED***'

# PASSWD="${SFTP_PASSWORD}"
FILE="/backup/backup-$DATE.tgz"
PORT='2222'
LOG_FILE="/var/log/sloth_backup.log"

# Exit immediately if a command exits with a non-zero status.
set -e

# Redirect all subsequent output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "--- Backup started: $(date) ---"

# Clean up old backups (older than 30 days)
echo "Cleaning up old backups..."
find /backup/backup-* -type f -mtime +30 -exec rm {} \;
echo "Old backups cleaned."

# Create the backup archive
echo "Creating backup archive: $FILE"
tar czvf "$FILE" /opt/Sloths/
echo "Backup archive created."

# Upload the backup archive via SFTP
echo "Uploading backup archive to $HOST:$PORT..."
lftp sftp://$USER:"${PASSWD}"@$HOST:$PORT -e "put $FILE; bye"
echo "Backup archive uploaded successfully."

echo "--- Backup finished: $(date) ---"
