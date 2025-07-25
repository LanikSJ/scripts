#!/usr/bin/env bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will get CPU stats for all the hosts.
#

dcadmin=$( security find-generic-password -l dcadmin -g 2>&1 1>/dev/null | cut -d'"' -f2 )

for i in $(seq 1 3); do (sshpass -p"$dcadmin" ssh dcadmin@10.200.5.$i "mpstat -P ALL"); done
