#!/usr/bin/env bash
#
# This script will return the list of AD groups from Email ID
# Usage: ./script john.doe@move.com
#

# Retrieve the Password from Keychain
export pass=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null | cut -d'"' -f2)

if [[ $pass = *"could not be found"* ]]; then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! " && exit 1
fi

# Set LDAP host based on location
ldap_host="corp.homestore.net"

ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(mail="${1}"))" memberOf \
  |grep memberOf |grep -v requesting |awk -F"=" '{print $2}' |awk -F"," '{print $1}' |sed 's/\\#/#/g' |sort -d
