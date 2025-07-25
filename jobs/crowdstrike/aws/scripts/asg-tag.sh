#!/bin/bash

for i in $(cat $1); do aws autoscaling create-or-update-tags --tags ResourceId=$i,ResourceType=auto-scaling-group,Key=cstag-owner,Value=techops-cicd,PropagateAtLaunch=true --profile csa --region us-west-2; done
for i in $(cat $1); do aws autoscaling describe-tags --filters Name=auto-scaling-group,Values=$i Name=key,Values=cstag-owner --profile csa --region us-west-2; done
