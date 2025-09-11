#!/usr/bin/env bash
# Wrapper for the expect scripts

while IFS= read -r i; do
    ~/bin/ipass/expect/scp_ubu.sh "$i" ~/Configs/ldap/nss/ubuntu14/template/ "$i"
done < ../lists/files.txt
