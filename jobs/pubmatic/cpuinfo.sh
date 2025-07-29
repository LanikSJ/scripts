#!/usr/bin/env bash
#
# Author: Ilan Erenstein
# Version:  1.01
#
# This script will get CPU stats for all the specified hosts in parallel.
#

# Retrieve the dcadmin password from the macOS keychain.
# It's crucial to handle this securely. Using SSH keys is generally preferred over passwords.
dcadmin=$(security find-generic-password -l dcadmin -g 2>&1 1>/dev/null | cut -d'"' -f2)

# Check if the password retrieval was successful.
if [ -z "$dcadmin" ]; then
    echo "Error: Could not retrieve 'dcadmin' password from keychain. Please ensure it's set up correctly." >&2
    exit 1
fi

# Define the list of target hosts.
# This array can be easily extended or made configurable (e.g., via command-line arguments).
declare -a hosts=("10.200.5.1" "10.200.5.2" "10.200.5.3")

# Number of parallel SSH connections. Adjust as needed.
# A good starting point is the number of hosts or CPU cores.
PARALLEL_JOBS=${#hosts[@]}

echo "Collecting CPU stats from hosts: ${hosts[*]} in parallel..."

# Execute mpstat on each host in parallel using xargs.
# The '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' options are used
# to bypass host key checking for simplicity, but this reduces security.
# For production environments, proper host key management is recommended.
printf "%s\n" "${hosts[@]}" | xargs -P "$PARALLEL_JOBS" -I {} bash -c "
    host=\"\$1\"
    dcadmin=\"\$2\"
    echo \"Connecting to \$host...\"
    if ! sshpass -p\"\$dcadmin\" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dcadmin@\"\$host\" \"mpstat -P ALL\"; then
        echo \"Error: Failed to connect or execute command on \$host\" >&2
    fi
" _ {} "$dcadmin"

echo "CPU stats collection complete."
