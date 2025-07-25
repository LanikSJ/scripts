#!/usr/bin/env bash

# This script uploads the new authorized keys file

#for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do ssh $i "cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak"; done
for i in $(cat ~/bin/ipass/lists/aws_ec2.txt); do scp -i ~/.ssh/aws/awsipass.pem.old ~/.ssh/aws/authorized_keys $i:~/.ssh/; done  
