#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

# List of IP addresses to perform DNS lookups on.
# Using a bash array for better readability and maintainability.
declare -a SERVERS=(
    "209.34.93.152"
    "209.34.93.153"
    "209.34.93.164"
    "209.34.93.179"
    "209.34.93.180"
    "209.34.93.186"
    "209.34.93.246"
    "209.34.93.26"
    "209.34.71.30"
    "209.34.71.31"
    "209.34.71.32"
    "209.34.71.33"
    "209.34.71.34"
    "209.34.71.55"
    "209.34.71.58"
    "209.34.71.63"
    "209.34.71.64"
    "209.34.71.40"
    "209.34.71.103"
    "209.34.71.61"
    "209.34.80.127"
)

# Output file for the hostnames.
# Changed from ping.log to hostnames.log as the script performs DNS lookups.
OUTPUT_FILE="hostnames.log"

# Clear the output file before starting.
true > "$OUTPUT_FILE"

echo "Starting DNS lookups for ${#SERVERS[@]} IP addresses..." | tee -a "$OUTPUT_FILE"
echo "Results will be saved to $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
echo "--------------------------------------------------" | tee -a "$OUTPUT_FILE"

# Loop through each IP address and perform a reverse DNS lookup.
for ip in "${SERVERS[@]}"; do
    echo "Looking up hostname for IP: $ip" | tee -a "$OUTPUT_FILE"
    # Use 'host' command for reverse DNS lookup, which is more modern than nslookup.
    # Extract the hostname from the output.
    hostname=$(host "$ip" | awk '/pointer/ {print $NF}' | sed 's/\.$//')

    if [ -n "$hostname" ]; then
        echo "  Hostname: $hostname" | tee -a "$OUTPUT_FILE"
    else
        echo "  Could not resolve hostname for $ip" | tee -a "$OUTPUT_FILE"
    fi
    echo "" | tee -a "$OUTPUT_FILE" # Add a blank line for readability
done

echo "--------------------------------------------------" | tee -a "$OUTPUT_FILE"
echo "DNS lookup process completed. Results are in $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
