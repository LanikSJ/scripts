#!/usr/bin/env bash
# This script will unsuspend users in GitHub Enterprise

if [[ `ifconfig |grep inet |grep 10.238` || `ifconfig |grep inet |grep 192.168` ]]; then
  echo && echo -n "Please enter the Username to unsupsend: "
  read USERNAME

  for i in $(echo $USERNAME |xargs -n1); do
    echo "Unsuspending $i ... "
    ssh github.move.com "ghe-user-unsuspend $i"
  done
else
  echo && echo "You need to be logged into the VPN to run this script! "
fi
