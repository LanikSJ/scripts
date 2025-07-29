#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

DATE=$(date +"%Y%m%d")
HOME="/var/www/html"
BACKUP="/opt/dump"
BACKUP_FILENAME="amg_html_backup_${DATE}.tgz"

echo "Tarballing and zipping the /var/www/html to $BACKUP/$BACKUP_FILENAME"
tar czpvf "$BACKUP/$BACKUP_FILENAME" "$HOME"

# Check if tar command was successful
if [ $? -ne 0 ]; then
    echo "Error: Tarball creation failed. Exiting."
    exit 1
fi

echo "Transferring $BACKUP_FILENAME to AMGMINT10..."
echo "---------------------------------------------------"
echo "                Begin FTP Session  "
echo "---------------------------------------------------"
# WARNING: Hardcoding FTP credentials in scripts is a security risk.
# Consider using more secure transfer methods like SFTP or SCP with SSH keys,
# or storing credentials securely (e.g., environment variables, secrets management).
echo "open 144.198.80.20
      quote USER amgmint10
      quote PASS qua4pu
      verbose
      binary
      cd ftpdropbox
      put \"$BACKUP/$BACKUP_FILENAME\" \"$BACKUP_FILENAME\"
      close
      quit" |/usr/bin/ftp -n

# Check if FTP command was successful
if [ $? -ne 0 ]; then
    echo "Error: FTP transfer failed. Exiting."
    exit 1
fi

echo "---------------------------------------------------"
echo "                End FTP Session  "
echo "---------------------------------------------------"

echo "Removing backups older than 10 days from $BACKUP"
find "$BACKUP"/amg_html_backup_*.tgz -type f -mtime +10 -exec rm {} \; -print
echo "All done now!!"
