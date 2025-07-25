#!/usr/bin/env bash

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	SERVERS=$(ec2-describe-instances --region us-west-1 --filter "key-name=awsipass" |awk '{print $4}' |grep ec2)
elif [ "$(uname)" == "Darwin" ]; then
	SERVERS=$(aws ec2 describe-instances --region=us-west-2 --output text --query 'Reservations[*].Instances[*].PrivateDnsName')
fi

if [ -f /etc/debian_version ]; then
	for i in $SERVERS; do ssh $i "echo 'sudo apt-get update && sudo apt-get -y install libc6' > glibc.sh && chmod +x glibc.sh"; done
	echo "Update file created"
	for i in $SERVERS; do ssh $i "./glibc.sh &"; done
	echo "Update file executed"
	for i in $SERVERS; do ssh $i "rm -rf ./glibc.sh"; done
	echo "Script removed"
elif [ -f /etc/redhat-release ]; then
	for i in $SERVERS; do ssh $i "echo 'sudo yum -y update glic*' > glibc.sh && chmod +x glibc.sh"; done
	echo "Update file created"
	for i in $SERVERS; do ssh $i "./glibc.sh &"; done
	echo "Update file executed"
	for i in $SERVERS; do ssh $i "rm -rf ./glibc.sh"; done
	echo "Script removed"
fi
