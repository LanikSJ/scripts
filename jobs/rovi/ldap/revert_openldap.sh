#!/bin/bash
#
# Ilan Erenstein 06/01/2010
# Version:  1.20 (Improved by Cline)
#
# Changelog:
#
# 06/01/2010 -- Changed the copy from bath to /root/backup
# 07/29/2025 -- Refactored for better error handling, readability, and reduced redundancy.
#
# This script will revert LDAP client installation changes to OpenLDAP.
#

# Environment variables
# date=$(date "+%Y%m%d_%H%M") # Uncomment if date is needed for logging
backup="/root/backup"
home_dir="/home" # Renamed 'dir' to 'home_dir' for clarity

# --- Functions ---

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: You must be root to run this script." >&2
        exit 1
    fi
}

# Function to pause script execution
pause() {
    printf "%s" "$*"
    read -r _
}

# Function to restore a file from backup
restore_file() {
    source_path="$backup/$1"
    dest_path="$2"
    echo "Restoring $dest_path"
    if cp -f "$source_path" "$dest_path"; then
        echo "Done!"
    else
        echo "Error: Failed to restore $dest_path. Backup file $source_path might not exist." >&2
        exit 1
    fi
}

# Function to handle permissions for home directories
handle_home_permissions() {
    echo "Checking if $home_dir is empty..."
    if [ -z "$(ls -A "$home_dir")" ]; then
        echo "$home_dir is empty!"
        return 0
    fi

    echo "Changing user/group permissions on home directories...."
    # Iterate over actual user home directories, excluding special entries like 'lost+found'
    for user_home in "$home_dir"/*; do
        if [ -d "$user_home" ]; then # Ensure it's a directory
            username=$(basename "$user_home")
            if id -u "$username" >/dev/null 2>&1; then # Check if user exists
                echo "Processing user: $username"
                if chown -R "$username" "$user_home" && chmod 700 "$user_home"; then
                    echo "User permissions for $username are Done!"
                else
                    echo "Error: Failed to change user permissions for $username." >&2
                fi

                groupname=$(id -gn "$username")
                if [ -n "$groupname" ]; then # Ensure group name is not empty
                    if chgrp -R "$groupname" "$user_home"; then
                        echo "Group permissions for $username are Done!"
                    else
                        echo "Error: Failed to change group permissions for $username." >&2
                    fi
                else
                    echo "Warning: Could not determine group for user $username." >&2
                fi
            else
                echo "Warning: User $username does not exist, skipping permissions for $user_home." >&2
            fi
        fi
    done
}

# --- Main Script Execution ---

check_root

# Add a pause so the above text can be read
pause "Press [Enter] to start the LDAP client restoration..."

# Files to be restored
declare -A files_to_restore=(
    ["issue"]="/etc/issue"
    ["sshd_config"]="/etc/ssh/sshd_config"
    ["sendmail.cf"]="/etc/mail/sendmail.cf"
    ["submit.cf"]="/etc/mail/submit.cf"
    ["aliases"]="/etc/aliases"
    ["ldap.conf"]="/etc/ldap.conf"
    ["nsswitch.conf"]="/etc/nsswitch.conf"
    ["system-auth"]="/etc/pam.d/system-auth"
    ["access.conf"]="/etc/security/access.conf"
)

for file_base in "${!files_to_restore[@]}"; do
    restore_file "$file_base" "${files_to_restore[$file_base]}"
done

echo "All files have been restored."

handle_home_permissions

echo "Restarting services"
newaliases # This command is specific to sendmail, might need 'postmap /etc/aliases' on some systems
service sshd restart
chkconfig nscd off # chkconfig is for SysVinit, systemctl disable nscd for systemd
service nscd stop
service sendmail stop

echo "LDAP changes have been reverted. All done!"
