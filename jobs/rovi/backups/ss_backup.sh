#!/bin/bash
set -e

DATE=$(date +"%Y%m%d")
GROUPS_DIR="/local/SiteScope/groups"
BACKUP_DIR="/root/ss-backups"

echo "Removing unneeded backup files from ${GROUPS_DIR}"
find "${GROUPS_DIR}" -name "*.bak" -type f -delete -print
echo "Zipping groups directory in SiteScope from ${GROUPS_DIR}"
tar czplvf "${BACKUP_DIR}/groups.${DATE}.tgz" "${GROUPS_DIR}"
echo "Removing backups older than 10 days from ${BACKUP_DIR}"
find "${BACKUP_DIR}" -name "*.tgz" -type f -mtime +10 -delete
echo "All done now!!"
