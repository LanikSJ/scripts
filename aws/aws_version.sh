#!/usr/bin/env bash
#
# Display AWS CLI Version.
# This script extracts and prints only the version number of the AWS CLI.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u

# Check if the 'aws' command is available
if ! command -v aws &> /dev/null; then
    printf "Error: AWS CLI is not installed or not found in PATH.\n" >&2
    exit 1
fi

# Get the AWS CLI version and extract only the version number
# Example output of 'aws --version': "aws-cli/2.1.3 Python/3.7.4 Darwin/19.3.0"
# We want to extract "2.1.3" from "aws-cli/2.1.3"
aws --version | awk '{print $1}' | cut -d'/' -f2
