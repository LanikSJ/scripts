#!/usr/bin/env bash
#
# This script will return the list of AD groups from Username
# Usage: ./script username
#

# Set LDAP host based on location
ldap_host="crowdstrike.sys"

# Check if username is passed
if [ -z "$1" ]; then 
  echo && echo "No Username Provided!" 
  echo "Usage: ./script username" && exit 1
fi

# Check if LDAP Host is set
if [ -z $ldap_host ]; then echo && echo "No LDAP Host Set!" && exit 1; fi

# Query LDAP Server
if ! ldapsearch -x -W -D "${USER}"@"${ldap_host}" -H ldaps://"${ldap_host}" \
  -b 'dc=crowdstrike,dc=sys' -o ldif-wrap=no sAMAccountName="$1" displayName \
  | awk -F":" '/displayName/ && !/requesting/ {print $2}' | xargs; then
  echo "Error: LDAP search failed or returned no results." >&2
  exit 1
fi
