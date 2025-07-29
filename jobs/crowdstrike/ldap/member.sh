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
if [ -z $ldap_host ]; then
  echo && echo "No LDAP Host Set!" && exit 1
fi

# Function to query LDAP server and extract group memberships
query_ldap_groups() {
  local username="$1"
  local ldap_host="$2"
  local ldap_base="dc=crowdstrike,dc=sys"

  ldapsearch -x -W -D "$USER"@"$ldap_host" -H ldaps://"$ldap_host" \
    -b "$ldap_base" -o ldif-wrap=no sAMAccountName="$username" memberOf 2>/dev/null \
    | awk -F'[=,]' '/memberOf/ && !/requesting/ {print $2}' | sort -d
}

# Query LDAP Server and store result
if ! groups=$(query_ldap_groups "$1" "$ldap_host"); then
  echo "Error: ldapsearch command failed. Please check your LDAP configuration or network connectivity."
  exit 1
fi

# Print the groups
echo "$groups"
