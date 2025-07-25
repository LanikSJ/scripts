#!/usr/bin/env bash
#
# This script will return a list users with terminated accounts from a list of users
# Usage: ./script userlist.txt
#

# Retrieve the Password from Keychain
export pass=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null | cut -d'"' -f2)

if [[ $pass = *"could not be found"* ]]; then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! " && exit 1
fi

# Set LDAP host based on location
ldap_host="corp.homestore.net"

USERLIST=$1

for username in `cat ${USERLIST}`; do
  if [[ `ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
    -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(sAMAccountName="${username}"))" | grep Terminated` ]]; then
      echo "${username} is a Terminated Account."
  fi
done
