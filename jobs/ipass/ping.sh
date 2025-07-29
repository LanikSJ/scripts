#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

# Define the list of servers as a bash array for better readability and maintainability.
SERVERS=(
    "up3"
    "sniff2"
    "download1"
    "vts3"
)

# Define the log file path.
LOG_FILE="ping.log"

# Define the number of pings per host.
PING_COUNT=10

# Clear the log file at the start of the script.
true > "$LOG_FILE"

echo "Starting ping test to hosts. Results will be logged to $LOG_FILE"
echo "---------------------------------------------------" | tee -a "$LOG_FILE"

# Loop through each server and perform the ping test.
for server in "${SERVERS[@]}"; do
    HOST="apac-hk-$server"
    echo "Pinging $HOST ($PING_COUNT times)..." | tee -a "$LOG_FILE"
    if ping -c "$PING_COUNT" "$HOST" >> "$LOG_FILE" 2>&1; then
        echo "Successfully pinged $HOST." | tee -a "$LOG_FILE"
    else
        echo "Failed to ping $HOST." | tee -a "$LOG_FILE"
    fi
    echo "---------------------------------------------------" | tee -a "$LOG_FILE"
done

echo "Ping test completed. Check $LOG_FILE for detailed results."
