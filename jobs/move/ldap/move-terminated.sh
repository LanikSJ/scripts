#!/usr/bin/env bash
#
# This script will return a list users with terminated accounts from a list of users
# Usage: ./script userlist.txt
#

set -euo pipefail

# Retrieve the Password from Keychain
if ! pass=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null | cut -d'"' -f2); then
  echo "Error: Unable to retrieve LDAP password from Keychain." >&2
  exit 1
fi

if [[ -z "$pass" ]]; then
  echo "Error: LDAP password retrieved from Keychain is empty." >&2
  exit 1
fi

# Set LDAP host based on location
ldap_host="corp.homestore.net"

USERLIST=$1

while IFS= read -r username; do
  if ldapsearch -h "$ldap_host" -D 'UnixLDPSvc@corp.homestore.net' -w "${pass}" -x \
    -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(sAMAccountName=${username}))" | grep -q Terminated; then
      echo "${username} is a Terminated Account."
  fi
done < "${USERLIST}"
