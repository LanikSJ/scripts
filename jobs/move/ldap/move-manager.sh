#!/usr/bin/env bash
#
# This script will return the manager Name and Email ID
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

export lastname=$(ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(mail="${1}"))" manager |grep manager: |awk '{print $2}' |sed 's/\\,//')

export firstname=$(ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)(mail="${1}"))" manager |grep manager: |awk '{print $3}' |sed 's/,OU=Users//')

export manager=$(echo $lastname, $firstname |awk 'NR%2{printf "%s ",$0;next;}1' |sed -e 's/[[:space:]]*$//')

export fullname=$(ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)($manager))" cn |grep cn: |awk -F":" '{print $2}' )

export email=$(ldapsearch -h $ldap_host -D 'UnixLDPSvc@corp.homestore.net' -w ${pass} -x \
  -b 'dc=corp,dc=homestore,dc=net' "(&(objectClass=user)($manager))" mail |grep mail: |awk '{print $2}')

export fullname=$(echo $fullname |awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }' |sed -e 's/,*$//')

echo "Name: $fullname" && echo "Email: $email"
