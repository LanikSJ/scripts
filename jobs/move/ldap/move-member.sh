#!/usr/bin/env bash
#
# This script will return the list of AD groups from Email ID
# Usage: ./script john.doe@move.com
#

# Retrieve the Password from Keychain
if ! pass=$(security find-generic-password -l ldap_pw -w 2>/dev/null); then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! "
  exit 1
fi
export pass # Export the password after successful retrieval

# Set LDAP host based on location
ldap_host="corp.homestore.net"

ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w "${pass}" -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(mail=${1}))" memberOf \
  | awk '/^memberOf: cn=/ && !/requesting/ {gsub(/\\#/,"#"); split($0, a, "cn="); split(a[2], b, ","); print b[1]}' | sort -d
