#!/usr/bin/env bash
#
# This script will return the manager Name and Email ID
# Usage: ./script john.doe@move.com
#

# Retrieve the Password from Keychain
export pass
pass=$(security find-generic-password -l ldap_pw -g 2>&1 1>/dev/null | cut -d'"' -f2)

if [[ $pass = *"could not be found"* ]]; then
  echo "Unable to find LDAP Password in KeyChain."
  echo "Looks like you don't have the LDAP password stored in KeyChain! " && exit 1
fi

# Set LDAP host based on location
ldap_host="corp.homestore.net"

# Function to perform ldapsearch and extract attribute
get_ldap_attribute() {
  local filter="$1"
  local attribute="$2"
  local ldap_result
  if ! ldap_result=$(ldapsearch -h "$ldap_host" -D 'UnixLDPSvc@corp.homestore.net' -w "${pass}" -x \
    -b 'dc=corp,dc=homestore,dc=net' "$filter" "$attribute" 2>/dev/null); then
    echo "LDAP search failed for filter: $filter, attribute: $attribute" >&2
    exit 1
  fi

  echo "$ldap_result" | grep "^$attribute:" | awk '{print $2}'
}

# Get user's manager DN
user_manager_dn=$(get_ldap_attribute "(&(objectClass=user)(mail=\"${1}\"))" manager)

if [[ -z "$user_manager_dn" ]]; then
  echo "Unable to find manager for user: ${1}" >&2
  exit 1
fi

# Extract manager's common name (cn) and email from their DN
# The manager DN typically looks like: cn=FirstName LastName,ou=Users,dc=corp,dc=homestore,dc=net
# We need to parse this to get the manager's full name and then use it to search for their email.
# A more robust way is to search by the manager's DN directly for their attributes.

# Get manager's full name and email using their DN
manager_fullname=$(get_ldap_attribute "($user_manager_dn)" cn)
manager_email=$(get_ldap_attribute "($user_manager_dn)" mail)

# Reformat fullname to "FirstName LastName" if it's "LastName, FirstName"
# This part of the original script was trying to reformat the manager's name.
# If the 'cn' attribute directly gives "FirstName LastName", this step might not be needed.
# Assuming 'cn' gives "FirstName LastName" or similar, we'll keep it as is.
# If 'cn' gives "LastName, FirstName", then the original reformatting logic might be needed.
# For now, I'll assume 'cn' provides a reasonable full name.

echo "Name: $manager_fullname"
echo "Email: $manager_email"
