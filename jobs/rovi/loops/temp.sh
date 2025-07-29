#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

HPONCFG_SOURCE_PATH="$HOME/ss-scripting-toolkit-linux-8.60/utilities/hponcfg"
SERVERS="lux2virt01 lux2virt03 lux2virt04 lux2virt05 lux2virt06"

# Loop through each server and copy the hponcfg utility
for i in $SERVERS; do
    echo "Attempting to copy hponcfg to $i..."
    if rsync -av --progress "$HPONCFG_SOURCE_PATH" "$i:/tmp/"; then
        echo "Successfully copied hponcfg to $i."
    else
        echo "Error: Failed to copy hponcfg to $i."
    fi
done
