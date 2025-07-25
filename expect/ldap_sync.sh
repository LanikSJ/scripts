#!/usr/bin/env bash
# Wrapper for the expect scripts

for i in $(cat ../lists/files.txt); do ~/bin/ipass/expect/scp_ubu.sh $i ~/Configs/ldap/nss/ubuntu14/tempalte/ $i; done
