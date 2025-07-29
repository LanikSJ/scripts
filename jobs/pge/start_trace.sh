#!/bin/bash

# Check if amustart command exists
if ! command -v amustart &> /dev/null
then
    printf "Error: 'amustart' command not found. Please ensure it is installed and in your PATH.\n" >&2
    exit 1
fi

printf "Starting traces on all lines.\n"

# Define the upper limit for the trace range
TRACE_UPPER_LIMIT=192

# Loop through the specified range and start traces
for i in $(seq 1 "$TRACE_UPPER_LIMIT"); do
    # Assuming 'amustart' is a command to start a trace with version 52 and port $i
    if ! amustart -v52 -p"$i"; then
        printf "Warning: 'amustart -v52 -p%s' failed.\n" "$i" >&2
    fi
done
printf "Traces started. Run 'end_trace' to stop them.\n"
