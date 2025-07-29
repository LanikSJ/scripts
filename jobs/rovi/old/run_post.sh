#!/bin/bash
# This script performs system setup and configuration tasks.

set -eu

# --- Configuration Variables ---
BASE_URL="http://ks1.sjc.trymedia.com/post"
TEMP_DIR="/tmp/run_post_script_temp_$$" # Unique temporary directory

# --- Helper Functions ---

# download_and_copy <src_on_server> <dest_path> <permissions> <owner>
download_and_copy() {
    local src_path_on_server="$1"
    local dest_path="$2"
    local permissions="${3:-}" # Optional: permissions (e.g., 644)
    local owner="${4:-}"      # Optional: owner (e.g., root:root)

    echo "Downloading ${BASE_URL}${src_path_on_server} to ${TEMP_DIR} and copying to ${dest_path}"
    wget -q -P "${TEMP_DIR}" "${BASE_URL}${src_path_on_server}"
    local filename
    filename="$(basename "${src_path_on_server}")"

    # Use install for better control over permissions and ownership
    if [[ -n "$permissions" && -n "$owner" ]]; then
        install -m "$permissions" -o "${owner%:*}" -g "${owner#*:}" "${TEMP_DIR}/${filename}" "${dest_path}"
    elif [[ -n "$permissions" ]]; then
        install -m "$permissions" "${TEMP_DIR}/${filename}" "${dest_path}"
    else
        cp -f "${TEMP_DIR}/${filename}" "${dest_path}"
    fi
}

# download_extract_and_copy <src_on_server> <dest_path>
download_extract_and_copy() {
    local src_path_on_server="$1"
    local dest_path="$2"

    echo "Downloading and extracting ${BASE_URL}${src_path_on_server} to ${TEMP_DIR}, then copying to ${dest_path}"
    wget -q -P "${TEMP_DIR}" "${BASE_URL}${src_path_on_server}"
    local filename
    filename="$(basename "${src_path_on_server}")"
    local extract_dir
    extract_dir="${TEMP_DIR}/$(basename "${filename}" .tgz)"

    mkdir -p "${extract_dir}"
    tar -C "${extract_dir}" -xzvf "${TEMP_DIR}/${filename}" >/dev/null

    # Find top-level extracted content
    local extracted_content
    extracted_content=()
    while IFS= read -r -d '' item; do
        extracted_content+=("$item")
    done < <(find "${extract_dir}" -mindepth 1 -maxdepth 1 -print0)

    if [[ ${#extracted_content[@]} -eq 1 && -d "${extracted_content[0]}" ]]; then
        cp -rf "${extracted_content[0]}/." "${dest_path}/"
    else
        cp -rf "${extract_dir}/." "${dest_path}/"
    fi
}

# --- Main Script Execution ---

echo "Starting system setup script..."

mkdir -p "${TEMP_DIR}"
cleanup() {
    echo "Cleaning up temporary directory: ${TEMP_DIR}"
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "Creating system directories..."
mkdir -p /root/src
mkdir -p /local

echo "Setting up iptables configuration..."
download_and_copy "/dli/conf/iptables" "/etc/sysconfig/" "644" "root:root"

echo "Setting up amhttpd..."
download_and_copy "/dli/conf/logs.conf" "/etc/httpd/conf.d/" "644" "root:root"
download_extract_and_copy "/src/trymedia/amhttpd_2.6.tgz" "/"

if [[ -f "/amhttpd_2.6/install.sh" ]]; then
    echo "Running amhttpd install script..."
    /bin/bash "/amhttpd_2.6/install.sh"
else
    echo "Warning: amhttpd install script not found at /amhttpd_2.6/install.sh"
fi

download_and_copy "/dli/conf/amhttpd" "/etc/logrotate.d/" "644" "root:root"

echo "Setting permissions for /var/log/amhttpd..."
mkdir -p /var/log/amhttpd
chmod -R 755 /var/log/amhttpd
chown -R root:root /var/log/amhttpd

echo "Adding amhttpd to chkconfig..."
chkconfig --add amhttpd || echo "amhttpd already added to chkconfig or failed."

echo "Setting up httpd.conf..."
if [[ -f "/etc/httpd/conf/httpd.conf" ]]; then
    echo "Backing up existing httpd.conf..."
    mv -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
fi
download_and_copy "/dli/conf/httpd.conf" "/etc/httpd/conf/" "644" "root:root"

echo "Setting up catalog sync user and directories..."
if ! id "uploadr" &>/dev/null; then
    useradd -s /bin/bash -c "uploadr, APP" -m -k /etc/skel -d /home/uploadr uploadr
else
    echo "User 'uploadr' already exists."
fi

download_extract_and_copy "/src/trymedia/rsync.tgz" "/home/uploadr"
chown -R uploadr:uploadr /home/uploadr/rsync

mkdir -p /catalog
chown -R uploadr:uploadr /catalog
chmod -R 755 /catalog

echo "Setting up RRD..."
download_extract_and_copy "/src/trymedia/rrd.tgz" "/"

echo "Scheduling RRD and Rsync via crontab..."
download_and_copy "/dli/conf/crontab" "/etc/" "644" "root:root"

echo "Setting up 3ware-utils and client tools..."
download_extract_and_copy "/src/trymedia/3ware-utils.tgz" "/"
chkconfig --add 3dm2 || echo "3dm2 already added to chkconfig or failed."

mkdir -p /local/3ware_twi
download_extract_and_copy "/src/trymedia/tw_cli-linux-x86-9.3.0.7.tgz" "/local/3ware_twi"

echo "Copying fstab configuration..."
download_and_copy "/dli/conf/fstab" "/etc/" "644" "root:root"

echo "Preparing for future network configuration and SSH access..."
if [[ -f "/etc/sysconfig/network-scripts/ifcfg-eth0" ]]; then
    sed 's/^/#/' /etc/sysconfig/network-scripts/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth0:1
else
    echo "Warning: /etc/sysconfig/network-scripts/ifcfg-eth0 not found."
fi

mkdir -p /root/.ssh
download_and_copy "/dli/conf/authorized_keys" "/root/.ssh/" "600" "root:root"

echo "Script execution completed."
