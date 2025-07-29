#!/bin/bash
set -euo pipefail

# File paths
ILO_CFG_ORIG="/tmp/ilo_cfg.xml"
ILO_CFG_FIXED="/tmp/ilo_cfg_fixed.xml"
ILO_LOG="/tmp/ilo.log"

# Dump iLO configuration to XML file
hponcfg -w "$ILO_CFG_ORIG"

# Delete lines 41 to 52 from the original config
sed '41,52d' "$ILO_CFG_ORIG" > "$ILO_CFG_FIXED"

# Replace IP prefix '10.110.208' with '10.110.60' in-place
sed -i 's/10\.110\.208/10.110.60/g' "$ILO_CFG_FIXED"

# Load fixed configuration and log the output
hponcfg -f "$ILO_CFG_FIXED" -l "$ILO_LOG"

# Extract IP_ADDRESS from XML, excluding lines containing GATEWAY
ip_address=$(grep 'IP_ADDRESS' "$ILO_CFG_FIXED" | grep -v GATEWAY | awk '{print $4}' | tr -d '"\/>')

if [[ -n "$ip_address" ]]; then
    echo "Pinging IP address: $ip_address"
    ping -c 10 "$ip_address"
else
    echo "Error: No IP_ADDRESS found to ping." >&2
    exit 1
fi
