#!/bin/bash
set -euo pipefail

MOUNT_POINT="/staging"
NFS_SERVER="10.110.212.14"
NFS_PATH="/var/linux/software"

# Unmount /staging if already mounted
if grep -qs "$MOUNT_POINT" /proc/mounts; then
    umount "$MOUNT_POINT"
fi

# Ensure mount directory exists
mkdir -p "$MOUNT_POINT"

# Remove conflicting package if installed
yum -y remove mysql-libs

# Mount the NFS share as read-only
mount -o ro,soft,nolock "${NFS_SERVER}:${NFS_PATH}" "$MOUNT_POINT"

# Determine RHEL version
RHEL_VERSION=""
if rpm -q --queryformat '%{VERSION}' redhat-release &>/dev/null; then
    RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release)
elif rpm -q --queryformat '%{VERSION}' redhat-release-server &>/dev/null; then
    RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release-server)
else
    echo "Cannot determine RHEL version." >&2
    umount "$MOUNT_POINT"
    exit 1
fi

# Install MySQL RPMs based on RHEL version
case "$RHEL_VERSION" in
    5)
        rpm -ivh "$MOUNT_POINT"/MySQL/EL5/MySQL-server*.rpm "$MOUNT_POINT"/MySQL/EL5/MySQL-client*.rpm "$MOUNT_POINT"/MySQL/EL5/MySQL-shared-compat*.rpm
        ;;
    6)
        rpm -ivh "$MOUNT_POINT"/MySQL/EL6/MySQL-server*.rpm "$MOUNT_POINT"/MySQL/EL6/MySQL-client*.rpm "$MOUNT_POINT"/MySQL/EL6/MySQL-shared-compat*.rpm
        ;;
    *)
        echo "This is not RHEL 5 or 6 Server." >&2
        umount "$MOUNT_POINT"
        exit 1
        ;;
esac

# Enable and start MySQL service
chkconfig mysql on
service mysql start

# Install PHP MySQL package
yum -y install php-mysql

# Clean up mount
umount "$MOUNT_POINT"
