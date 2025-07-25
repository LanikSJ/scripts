#!/usr/bin/env bash
#
# This script will add a new user to AWS.

for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do scp ~/bin/ipass/ierenstein.sh $i:/tmp/ && echo "Upload $i done!"; done 
for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do chmod +x /tmp/ierenstein.sh && echo "Perms on $i done!"; done
for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do ssh $i /tmp/ierenstein.sh && echo "Creating user on $i done!"; done
for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do ssh $i rm -rf /tmp/ierenstein.sh && echo "Removing script on $i done!"; done
