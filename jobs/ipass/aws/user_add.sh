#!/usr/bin/env bash
#
# This script will add a new user to AWS.

while IFS= read -r i; do
    scp ~/bin/ipass/ierenstein.sh "$i":/tmp/ && echo "Upload $i done!"
    ssh "$i" "chmod +x /tmp/ierenstein.sh" && echo "Perms on $i done!"
    ssh "$i" /tmp/ierenstein.sh && echo "Creating user on $i done!"
    ssh "$i" rm -rf /tmp/ierenstein.sh && echo "Removing script on $i done!"
done < ~/bin/ipass/lists/aws_ec2.txt
