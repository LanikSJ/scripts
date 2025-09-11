#!/usr/bin/env bash
# Wrapper for the expect scripts

while IFS= read -r i; do
    ~/bin/expect/ssh_co.sh "$i" "yum -y install php55w-mssql"
done < ~/bin/jobs/move/lists/socialbios.txt
