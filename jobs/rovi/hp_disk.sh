#!/bin/bash
#
# Ilan Erenstein
# Version:  1.0
#
# Changelog:
# - 05/15/2012 -- Initial version of the script
#
# This script will check for drive failures on HP systems.
#
# Nagios requires standard out text and an exit code
#
#   Exit Codes
#   0 = Normal
#   1 = Warning
#   2 = Critical
#   3 = Unknown

STATE_OK=0
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Set our variables
HPCLI='/usr/sbin/hpacucli'

# Check if CLI exists
if [ ! -x "$HPCLI" ]; then
    echo "UNKNOWN: $HPCLI doesn't exist or is not executable."
    exit $STATE_UNKNOWN
fi

# Run the hpacucli command and check for failures
# We capture the output of the drive status grep command

# Note: Run the command without quotes so it executes, not just as a string
failures=$($HPCLI ctrl all show config | grep -i fail || true)

if [[ -n $failures ]]; then
    echo "CRITICAL: Drive failures detected:"
    echo "$failures"
    exit $STATE_CRITICAL
else
    echo "OK: No Drive Failures Detected."
    exit $STATE_OK
fi
