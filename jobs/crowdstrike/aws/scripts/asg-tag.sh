#!/bin/bash

while IFS= read -r i; do aws autoscaling create-or-update-tags --tags ResourceId="$i",ResourceType=auto-scaling-group,Key=cstag-owner,Value=techops-cicd,PropagateAtLaunch=true --profile csa --region us-west-2; done < "$1"
while IFS= read -r i; do aws autoscaling describe-tags --filters Name=auto-scaling-group,Values="$i" Name=key,Values=cstag-owner --profile csa --region us-west-2; done < "$1"
