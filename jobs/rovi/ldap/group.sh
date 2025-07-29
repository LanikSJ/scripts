#!/usr/bin/env bash
#
# This script retrieves and displays a sorted list of group IDs from the system.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u

# Check for necessary commands
if ! command -v getent &> /dev/null; then
    printf "Error: 'getent' command not found. Please ensure it is installed and in your PATH.\n" >&2
    exit 1
fi

if ! command -v awk &> /dev/null; then
    printf "Error: 'awk' command not found. Please ensure it is installed and in your PATH.\n" >&2
    exit 1
fi

if ! command -v sort &> /dev/null; then
    printf "Error: 'sort' command not found. Please ensure it is installed and in your PATH.\n" >&2
    exit 1
fi

# Get group entries, extract the third field (GID), and sort them numerically
# The 'more' command is removed to allow for non-interactive execution.
# Users can pipe to 'more' or 'less' manually if pagination is desired.
getent group | awk -F':' '{print $3}' | sort -n
