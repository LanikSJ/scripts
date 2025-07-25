#!/usr/bin/env bash
# Wrapper for the expect scripts

for i in $(cat ~/bin/jobs/move/lists/socialbios.txt); do ~/bin/expect/ssh_co.sh $i "yum -y install php55w-mssql"; done
