#!/bin/sh

# Check if amuend command exists
if ! command -v amuend > /dev/null 2>&1
then
    printf "Error: 'amuend' command not found. Please ensure it is installed and in your PATH.\n" >&2
    exit 1
fi

printf "Stopping traces on all lines.\n"
for i in $(seq 1 192); do
    if ! amuend -v52 -l"$i"; then
        printf "Warning: 'amuend -v52 -l%s' failed.\n" "$i" >&2
    fi
done
printf "Traces stopped. Run 'start_trace' to start them again.\n"
