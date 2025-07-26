#!/bin/bash

for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-owner,Value=techops-cicd' --profile csa --region us-west-2; done
for i in $(cat $1); do aws ec2 describe-tags --filters Name=resource-id,Values=$i Name=key,Values=cstag-owner --profile csa --region us-west-2; done