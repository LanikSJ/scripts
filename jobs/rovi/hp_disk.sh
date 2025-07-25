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
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Set our variables
HPCLI='/usr/sbin/hpacucli'
STATUS='$HPCLI ctrl all show config|grep -i fail'

# Check make sure CLI is installed
[ -f $HPCLI ] || echo "$HPCLI doesn't exist!" && echo $STATE_UNKNOWN

# Run the check and produce output
echo $STATUS
if [ "$?" = "0" ]; then
	echo "Critical: $STATUS"
	echo $STATE_CRITICAL
else
	echo "OK: No Drive Failures Detected."
	echo $STATE_OK
fi
