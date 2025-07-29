#!/usr/bin/env bash
#
# This script will return the UID from Email ID
# Usage: ./script john.doe@move.com
#

# Retrieve the Password from Keychain
export pass
pass=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null | cut -d'"' -f2)

if [[ $pass = *"could not be found"* ]]; then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! " && exit 1
fi

# Set LDAP host and base DN based on location
ldap_host="corp.homestore.net"
ldap_base_dn="dc=corp,dc=homestore,dc=net"

# Perform LDAP search
if ! ldap_output=$(ldapsearch -h "$ldap_host" -D 'UnixLDPSvc@corp.homestore.net' -w "${pass}" -x \
  -b "$ldap_base_dn" "(&(objectClass=user)(mail=${1}))" sAMAccountName 2>&1); then
  echo "LDAP search failed: $ldap_output"
  exit 1
fi

# Extract sAMAccountName from LDAP output
echo "$ldap_output" | awk '/^sAMAccountName:/ && !/requesting/ {print $2}'
