#!/usr/bin/env bash
#
# This script will return the Email from UID
# Usage: ./script userid
#

# Retrieve the Password from Keychain
security_output=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null)
pass=$(echo "$security_output" | cut -d'"' -f2)
export pass

if [[ "$pass" = *"could not be found"* ]]; then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! " && exit 1
fi

# Set LDAP host based on location
ldap_host="corp.homestore.net"

ldapsearch -h "$ldap_host" -D 'UnixLDPSvc@corp.homestore.net' -w "${pass}" -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(sAMAccountName=\"${1}\"))" mail |grep mail:
