#!/usr/bin/env bash

# Configuration Section
# SFTP credentials come from the environment (never hardcode them):
#   export SFTP_HOST='ftp.example.com'
#   export SFTP_USER='your-username'
#   export SFTP_PASSWORD='...'
DATE=$(date +"%Y%m%d-%H%M")
HOST="${SFTP_HOST:?Set SFTP_HOST in the environment}"
USER="${SFTP_USER:?Set SFTP_USER in the environment}"
PASSWD="${SFTP_PASSWORD:-}"  # Ensure SFTP_PASSWORD is set in environment
FILE="/backup/backup-$DATE.tgz"
PORT="${SFTP_PORT:-22}"
LOG_FILE="/var/log/sloth_backup.log"
BACKUP_DIR="/backup"
SOURCE_DIR="/opt/Sloths"
RETENTION_DAYS=30

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
error_exit() {
    log "❌ ERROR: $1"
    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    if [[ -z "$PASSWD" ]]; then
        error_exit "SFTP_PASSWORD environment variable is not set."
    fi
    if ! command -v lftp &> /dev/null; then
        error_exit "lftp is not installed."
    fi
    if [[ ! -d "$SOURCE_DIR" ]]; then
        error_exit "Source directory $SOURCE_DIR does not exist."
    fi
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory $BACKUP_DIR."
    fi
}

# Function to clean up old backups
cleanup_old_backups() {
    log "🧹 Cleaning up old backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR"/backup-* -type f -mtime +$RETENTION_DAYS -exec rm {} \; 2>/dev/null || true
    log "✅ Old backups cleaned."
}

# Function to create backup archive
create_backup() {
    log "📦 Creating backup archive: $FILE"
    tar czf "$FILE" "$SOURCE_DIR" || error_exit "Failed to create backup archive."
    log "✅ Backup archive created."
}

# Function to upload backup via SFTP
upload_backup() {
    log "📤 Uploading backup archive to $HOST:$PORT..."
    lftp sftp://"$USER":"$PASSWD"@"$HOST":"$PORT" -e "put $FILE; bye" || error_exit "Failed to upload backup archive."
    log "✅ Backup archive uploaded successfully."
}

# Function to clean up local backup after successful upload
cleanup_local() {
    log "🗑️ Removing local backup file: $FILE"
    rm -f "$FILE" || log "⚠️ Warning: Failed to remove local backup file."
}

# Trap to handle script exit
trap 'log "⛔ Script interrupted or exited."; cleanup_local' EXIT

# Redirect all subsequent output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

log "🚀 --- Backup started ---"

# Main execution
check_prerequisites
cleanup_old_backups
create_backup
upload_backup
cleanup_local

log "🎉 --- Backup finished successfully ---"
