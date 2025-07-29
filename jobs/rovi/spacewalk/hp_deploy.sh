#!/bin/bash
set -euo pipefail

# Directory to mount remote NFS share
MOUNT_POINT="/staging"

# Check if $MOUNT_POINT is mounted, and unmount if so
if grep -qs "$MOUNT_POINT" /proc/mounts; then
    umount "$MOUNT_POINT"
fi

# Ensure mount point directory exists
mkdir -p "$MOUNT_POINT"

# Update NRPE config and restart service
rhncfg-client get /etc/nagios/nrpe.cfg
service nrpe restart

# Unalias cp if it exists
if alias cp &>/dev/null; then
    unalias cp
fi

# Get lowercase hostname once
hostname_lower=$(hostname | tr '[:upper:]' '[:lower:]')

# Determine BUILD IP based on hostname pattern
if grep -q 'tul' <<< "$hostname_lower"; then
    BUILD="10.202.51.32"
elif grep -q 'lux' <<< "$hostname_lower"; then
    BUILD="10.110.212.14"
elif grep -qE 'scl|sjc|amgsj' <<< "$hostname_lower"; then
    BUILD="10.28.208.20"
else
    BUILD="10.202.51.32"
fi

CRON_FILE="/var/spool/cron/root"
CRON_JOB="00 */1 * * * /usr/sbin/hp_disk.sh > /var/log/hp_disk_check.log"

# Add the cron job if missing
if ! grep -qF -- "$CRON_JOB" "$CRON_FILE"; then
    echo "$CRON_JOB" >> "$CRON_FILE"
fi

# Mount remote NFS share, copy script, set permissions, and unmount
mount -o ro,soft,nolock "${BUILD}:/var/linux/redhat/misc/6Server/scripts/" "$MOUNT_POINT"
cp "$MOUNT_POINT/HP/hp_disk.sh" /usr/sbin/
chmod 700 /usr/sbin/hp_disk.sh
umount "$MOUNT_POINT"
