#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

SERVERS=(
    "scl1sbxtapp1"
    "SCLIMPRVA01"
    "SCLNS10"
    "SCLPSDEVBLD01"
    "sclpsmedia01"
    "sclpssecure01"
    "sclpstv03"
    "sclpstv04"
    "sjc1androidtm1"
    "sjc1androidtw1"
    "sjc1bitapp1"
    "sjc1bitapp2"
    "sjc1corpw1"
    "SJC1CSDPOCD01"
    "SJC1CSDPOCD02"
    "SJC1CSDPOCM01"
    "SJC1CSDPOCP01"
    "sjc1csdtsc1"
    "sjc1cspadbwrt01"
    "sjc1cspadbwrt02"
    "sjc1cspadbwrt03"
    "sjc1cspadbwrt04"
    "sjc1cspadbwrt05"
    "sjc1cspadbwrt06"
    "sjc1cspadgwapp01"
    "sjc1cspadgwapp02"
    "sjc1cspadgwapp03"
    "sjc1cspadgwapp04"
    "sjc1cspadgwapp05"
    "sjc1cspadgwapp06"
    "sjc1cspadgwapp07"
    "sjc1cspadgwapp08"
    "sjc1cspadgwapp09"
    "sjc1cspadgwapp10"
    "sjc1cspadgwapp11"
    "sjc1cspadgwapp12"
    "sjc1cspadgwapp13"
    "sjc1cspadgwapp14"
    "sjc1cspadgwapp15"
    "sjc1cspadgwapp16"
    "sjc1cspadgwapp17"
    "sjc1cspadgwapp18"
    "sjc1cspadgwapp19"
    "sjc1cspadgwapp20"
    "sjc1cspadgwegs01"
    "sjc1cspadgwegs02"
    "sjc1cspadgwegs03"
    "sjc1cspadgwegs04"
    "sjc1cspadgwegs05"
    "sjc1cspadgwegs06"
    "sjc1cspadgwrmr01"
    "sjc1iddprd0"
    "sjc1iddprd1"
    "sjc1iddprd2"
    "sjc1iddprd3"
    "sjc1iddprd4"
    "sjc1iddprd5"
    "sjc1iddprd6"
    "sjc1iddprd7"
    "sjc1ipmdapp1"
    "sjc1ipmdapp2"
    "sjc1ipmddb1"
    "sjc1ipmtapp1"
    "sjc1itdsv01"
    "sjc1itdw1"
    "sjc1itpbuild01"
    "sjc1itpdivxm1"
    "sjc1itpdivxw1"
    "sjc1itpdivxw2"
    "sjc1itpsupportw1"
    "sjc1itpsupportw2"
    "sjc1itpsupportw3"
    "sjc1itpsupportw4"
    "sjc1itpsupportw5"
    "sjc1itpsupportw6"
    "sjc1itpsvn01"
    "sjc1itpswpxy01"
    "sjc1monyog1"
    "sjc1nsvpx1"
    "sjc1oratdb1"
    "sjc1oratdb2"
    "sjc1sbxnapp1"
    "sjc1sbxndb1"
    "sjc1wfndapp1"
    "sjccsdtdb01"
    "sjc1oqa01"
    "sjc1oqa02"
    "sjc1oqd01"
    "sjc1oqd02"
    "sjc1oqd03"
    "sjc1bipapp1"
    "sjc1bipapp2"
    "sjc1bipdb1"
    "sjc1bitdb1"
    "sjc1sbxpdb1"
    "sjc1soaapp1"
)

# Clear the log file at the beginning
true > ping.log

# Function to ping a single host and log the result
ping_host() {
    local host=$1
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] Pinging $host..." >> ping.log
    if ping -c 1 -W 1 $host &>/dev/null; then
        echo "[$timestamp] $host: UP" >> ping.log
    else
        echo "[$timestamp] $host: DOWN" >> ping.log
    fi
}

# Export the function so it can be used by xargs
export -f ping_host

# Ping all servers in parallel (e.g., 10 concurrent pings)
printf "%s\n" "${SERVERS[@]}" | xargs -P 10 -I {} bash -c 'ping_host "$@"' _ {}

echo "Ping results saved to ping.log"
