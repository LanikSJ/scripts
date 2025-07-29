#!/usr/bin/env bash
# Usage: ./hosts_cmd.sh command
# shellcheck disable=SC2029

SERVERS=$(ec2-describe-instances --region us-west-1 --filter "key-name=awsipass" |awk '{print $4}' |grep ec2 |sort -d)

for i in $SERVERS; do ssh "$i" "$1"; done
