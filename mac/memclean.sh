#!/usr/bin/env bash

# This script continuously monitors and forcefully terminates the 'UserEventAgent' process
# if it is found running. This is often used as a workaround for memory leaks
# or high CPU usage associated with this process on macOS.

# Ensure the script is run as root or with sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "🛑 This script must be run as root or with sudo."
  exit 1
fi

while true; do
    # Find the PID of the 'UserEventAgent' process, matching the exact process name.
    # '|| true' prevents the script from exiting if pgrep finds no matching process.
    pids=$(pgrep -x "UserEventAgent") || true

    if [[ -z "$pids" ]]; then
        echo "🔍 UserEventAgent not found. Sleeping for 5 seconds."
        sleep 5
    else
        echo "💥 UserEventAgent (PIDs: ${pids//$'\n'/, }) found. Forcefully terminating..."
        # Forcefully terminate the processes.
        # Use xargs to handle multiple PIDs returned by pgrep.
        echo "$pids" | xargs kill -9
        echo "✅ UserEventAgent (PIDs: ${pids//$'\n'/, }) terminated. Script will now exit."
        break # Exit the loop after termination
    fi
done
