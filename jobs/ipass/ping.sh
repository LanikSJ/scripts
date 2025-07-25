#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

SERVERS="up3			\
               	sniff2		\
               	download1		\
               	vts3"
for i in $SERVERS; do ping -c 10 apac-hk-$i && echo ; done 
