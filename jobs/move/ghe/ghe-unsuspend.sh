#!/usr/bin/env bash
# This script will unsuspend users in GitHub Enterprise

ifconfig_output=$(ifconfig)
if echo "$ifconfig_output" | grep -q "inet 10.238" || echo "$ifconfig_output" | grep -q "inet 192.168"; then
  echo && echo -n "Please enter the Username to unsupsend: "
  read -r USERNAME

  for i in $(echo "$USERNAME" |xargs -n1); do
    echo "Unsuspending $i ... "
    ssh github.move.com "ghe-user-unsuspend \"$i\""
  done
else
  echo && echo "You need to be logged into the VPN to run this script! "
fi
