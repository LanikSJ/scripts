#!/bin/bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will ping all the hosts listed below and create the ping.log output file.
#

SERVERS="lweb1-va.jobvite.com		\
	lweb2-va.jobvite.com		\
	lweb3-va.jobvite.com		\
	lweb4-va.jobvite.com		\
	lweb5-va.jobvite.com		\
	lweb6-va.jobvite.com		\
	lweb7-va.jobvite.com		\
	lweb8-va.jobvite.com		\
	lweb9-va.jobvite.com		\
            lweb10-va.jobvite.com"
for i in $SERVERS; do ssh ierenstein@$i "date" && ssh ierenstein@$i "hostname"; done
