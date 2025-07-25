#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

SERVERS="lux2virt01			\
               	lux2virt03		\
               	lux2virt04		\
               	lux2virt05		\
               	lux2virt06"
for i in $SERVERS; do rsync -av --progress ~/ss-scripting-toolkit-linux-8.60/utilities/hponcfg $i:/tmp/; done
