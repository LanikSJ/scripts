#!/usr/bin/env bash
# Wrapper for the expect scripts
# Usage: ./ldap_sync.sh <file-list>

while IFS= read -r i; do
    ~/bin/expect/scp_ubu.sh "$i" ~/Configs/ldap/nss/ubuntu14/template/ "$i"
done < "$1"
