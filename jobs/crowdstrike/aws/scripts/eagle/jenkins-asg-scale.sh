#!/bin/bash

 ASG="jenkins-idp-01-asg \
    jenkins-infra-eng-01-asg \
    jenkins-it-salesforce-01 \
    jenkins-techops-cicd-01-asg \
    joc-asg"

for i in $ASG; do
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $i --desired-capacity 0 --min-size 0 --max-size 0 --profile eagle-sso
    sleep 10
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $i --desired-capacity 1 --min-size 1 --max-size 1 --profile eagle-sso
done
