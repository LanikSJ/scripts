#!/usr/bin/env bash
#
# Ilan Erenstein
# Version:  1.09 (Improved)
#
# Changelog (Original):
# - 02/26/2010 -- Added backup of resolv.conf
# - 03/09/2010 -- Changed dir variable and changed directory perms to 750 instead of 700
# - 05/25/2010 -- Added Yum repos setup for rhelupd1 and 2 and sendmail setup for screlay.corporate.local
# - 06/01/2010 -- Added new backup folder in /root/backup if the backup already exists make a new one and append date+time to the file name
# - 06/22/2010 -- Added new menus for Update Servers, CORP vs ARMUS and added new CORP configs to the script
# - 10/04/2010 -- Modified the script to remove the sendmail queue before installing and compiling it
# - 10/13/2010 -- Make the appropriate changes to submit.mc to prevent relay through localhost
# - 10/18/2010 -- Added submit.mc and sendmail.mc to the template and script
# - 12/28/2010 -- Added removal of clientmqueue in sendmail
# - 01/28/2011 -- Chkconfig sendmail to on
#
# This script will setup LDAP authentication for Rovi ARMUS or CORPORATE domain.
# It handles server selection, configuration file downloads, system updates,
# and service management.
#
# This script requires root privileges to modify system configurations.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The exit status of a pipeline is the exit status of the last command.
set -o pipefail

# --- Configuration Variables ---
readonly SJC1_SERVER="rhelupd1.sjc.macrovision.com"
readonly SJC2_SERVER="rhelupd2.sjc.macrovision.com"
readonly CORP1_SERVER="rhelupd1.corporate.local"
readonly CORP2_SERVER="rhelupd2.corporate.local"
readonly BUILD1_SERVER="rhelbuild01.corporate.local"
readonly BUILD2_SERVER="rhelbuild02.corporate.local"

readonly BACKUP_BASE_DIR="/root/backup"
readonly TEMP_DIR
TEMP_DIR=$(mktemp -d -t ldap_migration_XXXXXX) # Secure temporary directory

# --- Helper Functions ---

# Function to print informational messages to stdout
print_info() {
    printf "Info: %s\n" "$1"
}

# Function to print warning messages to stderr
print_warning() {
    printf "Warning: %s\n" "$1" >&2
}

# Function to print error messages to stderr and exit
print_error_and_exit() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

# Function to add a pause, waiting for user input
pause() {
    read -r -p "$*"
}

# Function to check if a command exists
check_command_exists() {
    local cmd="$1"
    if ! command -v "${cmd}" &> /dev/null; then
        print_error_and_exit "'${cmd}' command not found. Please ensure it is installed and in your PATH."
    fi
}

# Function to restart a service, preferring systemctl over service command
restart_service() {
    local service_name="$1"
    print_info "Restarting service '${service_name}'..."
    if command -v systemctl &> /dev/null; then
        systemctl restart "${service_name}" || print_error_and_exit "Failed to restart service '${service_name}' using systemctl."
    elif command -v service &> /dev/null; then
        service "${service_name}" restart || print_error_and_exit "Failed to restart service '${service_name}' using service command."
    else
        print_error_and_exit "Neither 'systemctl' nor 'service' command found. Cannot restart '${service_name}'."
    fi
}

# Function to enable a service using chkconfig or systemctl
enable_service_on_boot() {
    local service_name="$1"
    print_info "Enabling service '${service_name}' on boot..."
    if command -v systemctl &> /dev/null; then
        systemctl enable "${service_name}" || print_error_and_exit "Failed to enable service '${service_name}' using systemctl."
    elif command -v chkconfig &> /dev/null; then
        chkconfig "${service_name}" on || print_error_and_exit "Failed to enable service '${service_name}' using chkconfig."
    else
        print_error_and_exit "Neither 'systemctl' nor 'chkconfig' command found. Cannot enable '${service_name}'."
    fi
}

# Function to handle backup, move, and permissions for a configuration file
# Arguments: $1=source_file_name (from /tmp), $2=destination_folder, $3=permissions (e.g., 644)
backup_and_move_file() {
    local source_file_name="$1"
    local dest_folder="$2"
    local permissions="$3"
    local full_dest_path="${dest_folder}/${source_file_name}"
    local backup_path="${BACKUP_BASE_DIR}/${source_file_name}"

    print_info "Processing ${full_dest_path}..."

    # Ensure destination folder exists
    mkdir -p "${dest_folder}" || print_error_and_exit "Failed to create destination directory '${dest_folder}'."

    # Create backup directory if it doesn't exist
    mkdir -p "${BACKUP_BASE_DIR}" || print_error_and_exit "Failed to create backup directory '${BACKUP_BASE_DIR}'."

    # Backup existing file if it exists
    if [ -f "${full_dest_path}" ]; then
        local timestamp
        timestamp=$(date "+%Y%m%d_%H%M%S")
        local dated_backup_path="${backup_path}.${timestamp}"
        print_info "Creating backup of existing ${full_dest_path} to ${dated_backup_path}"
        cp -f "${full_dest_path}" "${dated_backup_path}" || print_error_and_exit "Failed to backup ${full_dest_path}."
    else
        print_info "No existing file found at ${full_dest_path}. Skipping backup."
    fi

    # Move new file from temporary directory to destination
    if [ -f "${TEMP_DIR}/${source_file_name}" ]; then
        print_info "Moving new ${source_file_name} to ${full_dest_path}"
        mv -f "${TEMP_DIR}/${source_file_name}" "${full_dest_path}" || print_error_and_exit "Failed to move ${source_file_name} to ${full_dest_path}."
    else
        print_warning "New file ${TEMP_DIR}/${source_file_name} not found. Skipping move for this file."
        return 1 # Indicate that the new file was not found
    fi

    # Set permissions
    if [ -n "${permissions}" ]; then
        print_info "Setting permissions for ${full_dest_path} to ${permissions}"
        chmod "${permissions}" "${full_dest_path}" || print_error_and_exit "Failed to set permissions for ${full_dest_path}."
    fi
    print_info "Successfully processed ${full_dest_path}."
    return 0
}

# --- Main Script Execution ---

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error_and_exit "You must be root to run this script."
fi

# Ensure necessary commands are available early
check_command_exists "ping"
check_command_exists "wget"
check_command_exists "tar"
check_command_exists "sed"
check_command_exists "yum" # Assuming RHEL 5/6, yum is expected
check_command_exists "chmod"
check_command_exists "mv"
check_command_exists "cp"
check_command_exists "mkdir"
check_command_exists "rm"
check_command_exists "newaliases" # For sendmail

# --- User Interaction: Select Update Server ---
printf "\n"
printf "This script is used to install LDAP configuration into RHEL5.\n"
printf "Make sure you have connectivity to one of the Update Servers. Otherwise this script will not work.\n"
printf "Check your /etc/resolv.conf and if you're using 192.168.0.42/43/44 choose option 1. If option 1 doesn't work try option 2.\n"
printf "\nWhich update servers should we use for the update? :\n"
printf "       1.  rhelupd1/2 on sjc.macrovision.com (Equinix)\n"
printf "       2.  rhelupd1/2 on corporate.local (Equinix)\n"
printf "       3.  rhelbuild01/02 -- Build Servers (Corporate)\n"

printf "\nEnter choice [1-3, press any key to exit]: "
read -r channelchoice

upd_server=""
case "${channelchoice}" in
  1)
    print_info "Checking connectivity to Equinix Update Servers..."
    if ping -c 1 "${SJC1_SERVER}" &> /dev/null; then
        upd_server="${SJC1_SERVER}"
        print_info "Using ${upd_server} server for this update."
    elif ping -c 1 "${SJC2_SERVER}" &> /dev/null; then
        upd_server="${SJC2_SERVER}"
        print_info "Using ${upd_server} server for this update."
    else
        print_error_and_exit "Sorry, it appears this machine has no ICMP connectivity to Equinix Update Servers."
    fi
    ;;
  2)
    print_info "Checking connectivity to Corporate Update Servers..."
    if ping -c 1 "${CORP1_SERVER}" &> /dev/null; then
        upd_server="${CORP1_SERVER}"
        print_info "Using ${upd_server} server for this update."
    elif ping -c 1 "${CORP2_SERVER}" &> /dev/null; then
        upd_server="${CORP2_SERVER}"
        print_info "Using ${upd_server} server for this update."
    else
        print_error_and_exit "Sorry, it appears this machine has no ICMP connectivity to Corporate Update Servers."
    fi
    ;;
  3)
    print_info "Checking connectivity to Corporate Build Servers..."
    if ping -c 1 "${BUILD1_SERVER}" &> /dev/null; then
        upd_server="${BUILD1_SERVER}"
        print_info "Using ${upd_server} server for this update."
    elif ping -c 1 "${BUILD2_SERVER}" &> /dev/null; then
        upd_server="${BUILD2_SERVER}"
        print_info "Using ${BUILD2_SERVER} server for this update." # Fixed variable name
    else
        print_error_and_exit "Sorry, it appears this machine has no ICMP connectivity to Corporate Build Servers."
    fi
    ;;
  *)
    print_info "This script will now exit!"
    exit 0
    ;;
esac

# --- User Interaction: Select LDAP Configuration Type ---
printf "\n"
printf "ARMUS sjc1extdc1/2\n"
printf "CORPORATE scl1ad1/2\n"
printf "\nWhich LDAP configuration would you like? :\n"
printf "	1. ARMUS\n"
printf "	2. CORPORATE\n"

printf "\nEnter choice [1-2, press any key to exit]: "
read -r channelchoice

ldap_config_type=""
case "${channelchoice}" in
  1)
    ldap_config_type="armus"
    ;;
  2)
    ldap_config_type="corp"
    ;;
  *)
    print_info "This script will now exit!"
    exit 0
    ;;
esac

# --- Download and Extract LDAP Configuration Files ---
tar_gz_file="ldap_conf_${ldap_config_type}.tar.gz"
download_url="http://${upd_server}/redhat/misc/5Server/templates/ldap/${tar_gz_file}"
downloaded_path="${TEMP_DIR}/${tar_gz_file}"

print_info "Downloading LDAP ${ldap_config_type^^} configuration files from ${download_url}!"
wget -q -O "${downloaded_path}" "${download_url}" || print_error_and_exit "LDAP ${ldap_config_type^^} configuration didn't download from ${download_url}!"
print_info "Download complete!"

print_info "Extracting LDAP configuration to ${TEMP_DIR}..."
tar xvzf "${downloaded_path}" -C "${TEMP_DIR}" || print_error_and_exit "Failed to extract LDAP configuration files to ${TEMP_DIR}!"
print_info "Extraction complete!"

# --- Setting up Yum Repos (ARMUS specific) ---
if [ "${ldap_config_type}" = "armus" ]; then
    print_info "Setting up Yum Repos for ARMUS configuration."
    # These sed commands are specific to ARMUS configuration and assume the files are in /etc/yum.repos.d/
    sed -i 's/rhelbuild01.macrovision.com/rhelupd1.sjc.macrovision.com/g' /etc/yum.repos.d/*.repo || print_warning "Failed to update rhelbuild01.macrovision.com in yum repos."
    sed -i 's/rhelbuild02.macrovision.com/rhelupd2.sjc.macrovision.com/g' /etc/yum.repos.d/*.repo || print_warning "Failed to update rhelbuild02.macrovision.com in yum repos."
    print_info "Yum Repos setup complete."
fi

# --- Setting up Sendmail ---
print_info "Setting up sendmail."
yum clean all || print_warning "Failed to clean yum cache."
yum -y install sendmail-cf || print_error_and_exit "Failed to install sendmail-cf."

# Check for and remove sendmail.cf.rpmnew if it exists
if [ -f "/etc/mail/sendmail.cf.rpmnew" ]; then
    print_info "Removing /etc/mail/sendmail.cf.rpmnew."
    rm -f "/etc/mail/sendmail.cf.rpmnew" || print_warning "Failed to remove /etc/mail/sendmail.cf.rpmnew."
fi

print_info "Stopping sendmail service and clearing mail queues."
restart_service "sendmail" # Stop and restart to ensure clean state
rm -rf /var/spool/mqueue/* || print_warning "Failed to clear /var/spool/mqueue."
rm -rf /var/spool/clientmqueue/* || print_warning "Failed to clear /var/spool/clientmqueue."
print_info "Sendmail setup complete."

# --- File Copying and Permissions (using the new function) ---
# Note: The original script had a complex backup/move logic for each file.
# The new `backup_and_move_file` function simplifies this.
# The original script also had a specific logic for /etc/mail/ldap (only add if not exists)
# and /etc/openldap/ldap.conf (remove then add symlink). These will be handled specifically.

# /etc/issue
backup_and_move_file "issue" "/etc" "444"

# /etc/ssh/sshd_config
backup_and_move_file "sshd_config" "/etc/ssh" "600"

# /etc/mail/sendmail.cf
backup_and_move_file "sendmail.cf" "/etc/mail" "444"

# /etc/mail/sendmail.mc
backup_and_move_file "sendmail.mc" "/etc/mail" "" # Permissions set later if needed

# /etc/mail/submit.cf
backup_and_move_file "submit.cf" "/etc/mail" "444"

# /etc/mail/submit.mc
backup_and_move_file "submit.mc" "/etc/mail" "" # Permissions set later if needed

# /etc/mail/ldap (special case: only add if not exists in original)
print_info "Processing /etc/mail/ldap..."
if [ ! -f "/etc/mail/ldap" ]; then
    if [ -f "${TEMP_DIR}/ldap" ]; then
        print_info "Adding new /etc/mail/ldap."
        mv -f "${TEMP_DIR}/ldap" "/etc/mail/ldap" || print_error_and_exit "Failed to add new /etc/mail/ldap."
        chmod 400 "/etc/mail/ldap" || print_error_and_exit "Failed to set permissions for /etc/mail/ldap."
        print_info "Successfully added /etc/mail/ldap."
    else
        print_warning "New file ${TEMP_DIR}/ldap not found. Skipping move for /etc/mail/ldap."
    fi
else
    print_info "/etc/mail/ldap already exists. Skipping addition."
    # If it exists, we should still ensure permissions are correct
    chmod 400 "/etc/mail/ldap" || print_error_and_exit "Failed to set permissions for existing /etc/mail/ldap."
fi

# /etc/aliases
backup_and_move_file "aliases" "/etc" "" # Permissions set later if needed

# cacerts (special case: generic *9.0 pattern)
print_info "Adding new LDAP certs to /etc/openldap/cacerts..."
mkdir -p "/etc/openldap/cacerts" || print_error_and_exit "Failed to create /etc/openldap/cacerts."
# Find all files ending with '9.0' in the temporary directory and move them
find "${TEMP_DIR}" -maxdepth 1 -type f -name "*9.0" -exec mv -f {} "/etc/openldap/cacerts/" \; || print_warning "Failed to move some LDAP certs ending with *9.0."
chmod 644 /etc/openldap/cacerts/* || print_warning "Failed to set permissions for LDAP certs."
print_info "LDAP certs processed."

# /etc/openldap/ldap.conf (special case: remove then symlink)
print_info "Processing /etc/openldap/ldap.conf..."
openldap_ldap_conf="/etc/openldap/ldap.conf"
etc_ldap_conf="/etc/ldap.conf"

# Backup existing /etc/openldap/ldap.conf if it exists
if [ -f "${openldap_ldap_conf}" ]; then
    timestamp=$(date "+%Y%m%d_%H%M%S")
    dated_backup_path="${BACKUP_BASE_DIR}/openldap_ldap.conf.${timestamp}"
    print_info "Creating backup of existing ${openldap_ldap_conf} to ${dated_backup_path}"
    cp -f "${openldap_ldap_conf}" "${dated_backup_path}" || print_error_and_exit "Failed to backup ${openldap_ldap_conf}."
fi

# Remove existing /etc/openldap/ldap.conf (whether file or symlink)
if [ -e "${openldap_ldap_conf}" ]; then # -e checks for existence of file or symlink
    print_info "Removing existing ${openldap_ldap_conf}."
    rm -rf "${openldap_ldap_conf}" || print_error_and_exit "Failed to remove existing ${openldap_ldap_conf}."
fi

# Move new /etc/ldap.conf from temporary directory
backup_and_move_file "ldap.conf" "/etc" "644" # This handles /etc/ldap.conf

# Create symbolic link
print_info "Creating symbolic link from ${etc_ldap_conf} to ${openldap_ldap_conf}."
ln -s "${etc_ldap_conf}" "${openldap_ldap_conf}" || print_error_and_exit "Failed to create symbolic link for ${openldap_ldap_conf}."
print_info "Symbolic link created."

# /etc/nsswitch.conf
backup_and_move_file "nsswitch.conf" "/etc" "644"

# /etc/pam.d/system-auth (original uses system-auth-ac, assuming that's the file name in tarball)
backup_and_move_file "system-auth-ac" "/etc/pam.d" "644"

# /etc/security/access.conf
backup_and_move_file "access.conf" "/etc/security" "644"

# /etc/resolv.conf
backup_and_move_file "resolv.conf" "/etc" "444"

# --- Final Permissions (consolidated) ---
print_info "Consolidating and setting final permissions on moved files..."
chmod 444 /etc/issue /etc/mail/sendmail.cf /etc/mail/submit.cf || print_warning "Failed to set permissions for issue/sendmail.cf/submit.cf."
chmod 600 /etc/ssh/sshd_config || print_warning "Failed to set permissions for sshd_config."
chmod 400 /etc/mail/ldap || print_warning "Failed to set permissions for /etc/mail/ldap."
chmod 644 /etc/openldap/cacerts/* /etc/ldap.conf /etc/nsswitch.conf /etc/pam.d/system-auth-ac /etc/security/access.conf || print_warning "Failed to set permissions for other config files."
print_info "File permissions updated."

# --- Restarting Services ---
print_info "Restarting necessary services."
enable_service_on_boot "sendmail"
enable_service_on_boot "nscd"

print_info "Clearing nscd cache."
rm -f /var/db/nscd/* || print_warning "Failed to clear nscd cache."

restart_service "nscd"
restart_service "sshd"
print_info "Running newaliases for sendmail."
newaliases || print_warning "Failed to run newaliases."
restart_service "sendmail"

# --- Cleanup Temporary Directory ---
print_info "Cleaning up temporary directory: ${TEMP_DIR}"
rm -rf "${TEMP_DIR}" || print_warning "Failed to remove temporary directory ${TEMP_DIR}."

# --- Home Directory Permissions (Removed - handled by home.sh) ---
# The original script contained a large block for home directory renaming and permissions.
# This functionality has been moved to a separate, improved script (home.sh).
# If this functionality is still desired, please run home.sh after this script.

print_info "All done!"
print_info "LDAP Installation has been completed."
print_warning "DON'T LOGOFF YET! Test your login in another connection to this server."
print_info "You should now be able to login to this server with your ARMUS credentials."
