#!/bin/bash
set -euo pipefail

MOUNT_POINT="/staging"
NFS_SERVER="10.202.51.32"
NFS_PATH="/ks"

# Unmount /staging if already mounted
if grep -qs "$MOUNT_POINT" /proc/mounts; then
    umount "$MOUNT_POINT"
fi

# Ensure the mount point exists
mkdir -p "$MOUNT_POINT"

# Mount the remote NFS share
mount -o ro,soft,nolock "${NFS_SERVER}:${NFS_PATH}" "$MOUNT_POINT"

# Detect RHEL version and install Nagios RPMs
if rpm -q --queryformat '%{VERSION}' redhat-release &>/dev/null; then
    VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release)
elif rpm -q --queryformat '%{VERSION}' redhat-release-server &>/dev/null; then
    VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release-server)
else
    echo "Unable to determine RHEL version." >&2
    umount "$MOUNT_POINT"
    exit 1
fi

case "$VERSION" in
    5Server)
        rpm -Uvh "$MOUNT_POINT/Utils/Nagios/EL5/x86_64/"*.rpm
        ;;
    6Server)
        rpm -Uvh "$MOUNT_POINT/Utils/Nagios/EL6/x86_64/"*.rpm --nodeps
        ;;
    *)
        echo "This is not RHEL5/6 Server" >&2
        umount "$MOUNT_POINT"
        exit 1
        ;;
esac

# Set ownership for nagios
chown -R nagios:nagios /usr/lib/nagios

# Enable and restart NRPE service
chkconfig nrpe on
service nrpe restart

# Clean up
umount "$MOUNT_POINT"
