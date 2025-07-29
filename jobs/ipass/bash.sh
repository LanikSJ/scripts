#!/usr/bin/env bash
#
# Author: Ilan Erenstein
# Version:  1.00
#
# This script will update bash on all the hosts.
#

pass=$( security find-generic-password -l root_pw -g 2>&1 1>/dev/null | cut -d'"' -f2 )

while IFS= read -r i; do sshpass -p"$pass" scp ~/Downloads/bash*.rpm "root@$i:~"; done < list.txt
while IFS= read -r i; do sshpass -p"$pass" ssh "root@$i" "rpm -Uvh /root/bash*.rpm"; done < list.txt
 
#while IFS= read -r i; do sshpass -p"$pass" ssh "root@$i" "yum clean all; yum -y update bash"; done

#sudo apt-get update && sudo apt-get install bash
