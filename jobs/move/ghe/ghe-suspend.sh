#!/usr/bin/env bash
# This script will suspend all dormant users in GitHub Enterprise

if [[ `ifconfig |grep inet |grep 10.238` || `ifconfig |grep inet |grep 192.168` ]]; then
  export GHE_URL="https://github.move.com/stafftools/reports/dormant_users.csv"
  export DORMANT_USERS=$(curl -sSL -u $USER:$GHE_TOKEN $GHE_URL |awk -F"," '{print $3}' |grep -Ev 'login|jenkins|github')

  echo && echo "Here's the list of current dormant users: " && echo
  curl -sSL -u $USER:$GHE_TOKEN $GHE_URL |grep -Ev 'login|jenkins|github'

  for i in $DORMANT_USERS; do
    echo && echo "Suspending $i ... "
    ssh ghe "ghe-user-suspend $i"
  done
else
  echo && echo "You need to be logged into the VPN to run this script! "
fi
