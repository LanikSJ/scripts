#!/bin/sh
#
# Ilan Erenstein 10/07/2010
# Version:  1.01
#
# This script will setup SNMPD for cacti.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions ---

# Function for logging messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR: You must be root to run this script."
        exit 1
    fi
    log "Running as root."
}

# Function to check for command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Variables ---
SJC1="rhelupd1.sjc.macrovision.com"
SJC2="rhelupd2.sjc.macrovision.com"
CORP1="rhelupd1.corporate.local"
CORP2="rhelupd2.corporate.local"
BUILD1="rhelbuild01.corporate.local"
BUILD2="rhelbuild02.corporate.local"

UPDATE_SERVER=""

# --- Main Script Logic ---

check_root

# Define Update Servers
select_update_server() {
    log "Starting update server selection."
    cat << MENU

 This script is used to install SNMPD configuration into RHEL5.

 Make sure you have connectivity to one of the Update Servers. Otherwise this script will not work.
 Check your /etc/resolv.conf and if you're using 192.168.0.42/43/44 choose option 1. If option 1 doesn't work try option 2.

 Which update servers should we use for the update? :

       1.  rhelupd1/2 on sjc.macrovision.com (Equinix)
       2.  rhelupd1/2 on corporate.local (Equinix)
       3.  rhelbuild01/02 -- Build Servers (Corporate)

MENU

    printf "Enter choice [1-3, press any key to exit]: "
    read -r channel_choice

    case "$channel_choice" in
        1)
            if ping -c 1 "$SJC1" > /dev/null 2>&1; then
                UPDATE_SERVER="$SJC1"
                log "Using $UPDATE_SERVER server for this update."
            elif ping -c 1 "$SJC2" > /dev/null 2>&1; then
                UPDATE_SERVER="$SJC2"
                log "Using $UPDATE_SERVER server for this update."
            else
                log "ERROR: No ICMP connectivity to Equinix Update Servers ($SJC1, $SJC2)."
                exit 1
            fi
            ;;
        2)
            if ping -c 1 "$CORP1" > /dev/null 2>&1; then
                UPDATE_SERVER="$CORP1"
                log "Using $UPDATE_SERVER server for this update."
            elif ping -c 1 "$CORP2" > /dev/null 2>&1; then
                UPDATE_SERVER="$CORP2"
                log "Using $UPDATE_SERVER server for this update."
            else
                log "ERROR: No ICMP connectivity to Corporate Update Servers ($CORP1, $CORP2)."
                exit 1
            fi
            ;;
        3)
            if ping -c 1 "$BUILD1" > /dev/null 2>&1; then
                UPDATE_SERVER="$BUILD1"
                log "Using $UPDATE_SERVER server for this update."
            elif ping -c 1 "$BUILD2" > /dev/null 2>&1; then
                UPDATE_SERVER="$BUILD2"
                log "Using $BUILD2 server for this update."
            else
                log "ERROR: No ICMP connectivity to Corporate Build Servers ($BUILD1, $BUILD2)."
                exit 1
            fi
            ;;
        *)
            log "Exiting script."
            exit 0
            ;;
    esac
}

install_snmpd() {
    log "Installing SNMPD..."
    if ! command_exists yum; then
        log "ERROR: 'yum' command not found. This script requires a RHEL-based system."
        exit 1
    fi

    printf "Proceed with SNMPD installation? (y/N): "
    read -r confirm_install
    case "$confirm_install" in
        [Yy]*)
            ;;
        *)
            log "SNMPD installation aborted by user."
            exit 0
            ;;
    esac

    yum install -y net-snmp.x86_64 net-snmp-libs.x86_64 net-snmp-utils.x86_64 || { log "ERROR: SNMPD installation failed."; exit 1; }
    log "SNMPD installation complete."
}

download_cacti_configs() {
    log "WARNING: Downloading Cacti Configs using HTTP. This is insecure. Consider using HTTPS if available."
    log "Downloading Cacti Configs from http://$UPDATE_SERVER/redhat/misc/5Server/templates/snmpd/cacti.tar.gz..."
    if ! command_exists wget; then
        log "ERROR: 'wget' command not found. Please install wget."
        exit 1
    fi
    wget -O /tmp/cacti.tar.gz "http://$UPDATE_SERVER/redhat/misc/5Server/templates/snmpd/cacti.tar.gz" || { log "ERROR: Cacti configuration didn't download!"; exit 1; }
    log "Cacti configuration download complete."
}

extract_cacti_configs() {
    log "Extracting Cacti Configs to /tmp..."
    (cd /tmp && tar xzvvf cacti.tar.gz) || { log "ERROR: Cacti configuration didn't extract!"; exit 1; }
    log "Cacti configuration extraction complete."
}

add_snmpd_configs() {
    log "Adding SNMPD Configs..."
    mv -f /tmp/snmpd.conf /etc/snmp/snmpd.conf || { log "ERROR: Failed to move snmpd.conf."; exit 1; }
    mv -f /tmp/snmpd.options /etc/sysconfig/snmpd.options || { log "ERROR: Failed to move snmpd.options."; exit 1; }
    log "SNMPD Configs added."
}

install_snmp_disk_io() {
    log "Installing SNMP Disk I/O..."
    install -m 0755 -o root -g root -p -v /tmp/snmpdiskio /usr/local/bin/ || { log "ERROR: Failed to install snmpdiskio."; exit 1; }
    rm -f /tmp/snmpdiskio
    log "SNMP Disk I/O installed."
}

start_snmpd_service() {
    log "Starting SNMPD service..."
    chkconfig snmpd on || { log "ERROR: Failed to enable snmpd service with chkconfig."; exit 1; }
    service snmpd start || { log "ERROR: Failed to start snmpd service."; exit 1; }
    log "SNMPD service started."
}

# --- Execution Flow ---
select_update_server
install_snmpd
download_cacti_configs
extract_cacti_configs
add_snmpd_configs
install_snmp_disk_io
start_snmpd_service

log "Script execution finished successfully."
