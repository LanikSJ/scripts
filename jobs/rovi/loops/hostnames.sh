#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

SERVERS="209.34.93.152			\
               	209.34.93.153		\
               	209.34.93.164		\
               	209.34.93.179		\
               	209.34.93.180		\
               	209.34.93.186		\
               	209.34.93.246		\
               	209.34.93.26		\
               	209.34.71.30		\
               	209.34.71.31		\
               	209.34.71.32		\
               	209.34.71.33		\
               	209.34.71.34		\
               	209.34.71.55		\
               	209.34.71.58		\
               	209.34.71.63		\
               	209.34.71.64		\
               	209.34.71.40		\
               	209.34.71.103		\
               	209.34.71.61		\
               	209.34.80.127"
for i in $SERVERS; do nslookup $i |awk -F"=" '{print $2}' |awk '/./'; done
