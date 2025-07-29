#!/bin/bash
set -euo pipefail

MOUNT_POINT="/staging"

# Unmount if already mounted
if grep -qs "$MOUNT_POINT" /proc/mounts; then
    umount "$MOUNT_POINT"
fi

# Ensure mount point directory exists
mkdir -p "$MOUNT_POINT"

# Unalias cp if exists
if alias cp &>/dev/null; then
    unalias cp
fi

# Determine SERVER and LOCATION based on hostname
hostname_lower=$(hostname | tr '[:upper:]' '[:lower:]')

if grep -q "tul" <<< "$hostname_lower"; then
    SERVER="10.202.51.32"
    LOCATION="Tulsa"
elif grep -q "lux" <<< "$hostname_lower"; then
    SERVER="10.110.212.14"
    LOCATION="Luxembourg"
else
    SERVER="10.202.51.32"
    LOCATION="Tulsa"
fi

# Mount remote NFS share
if mount -o ro,soft,nolock "${SERVER}:/var/linux/redhat/misc/6Server/scripts/" "$MOUNT_POINT"; then
    echo "$LOCATION Mounted"
else
    echo "Mount Failed" >&2
    exit 1
fi

# Determine program name based on hostname
if grep -q "srcapp" <<< "$hostname_lower"; then
    prog="recsd"
elif grep -q "srsapp" <<< "$hostname_lower"; then
    prog="solrd"
elif grep -q "srcmt" <<< "$hostname_lower"; then
    prog="cmtd"
else
    echo "This is not a Cluster App, Solr App or Cluster Manager" >&2
    umount "$MOUNT_POINT"
    exit 1
fi

# Check if init script exists
if [[ ! -f "/etc/init.d/$prog" ]]; then
    echo "$prog didn't exist"
fi

# Copy the init script, set permissions, enable on chkconfig
cp "$MOUNT_POINT/SnR/$prog" "/etc/init.d/"
chmod +x "/etc/init.d/$prog"
chkconfig "$prog" on
echo "Deployed $prog"

# Unmount staging directory
umount "$MOUNT_POINT"
