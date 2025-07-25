#!/bin/bash

for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-accounting,Value=cogs' --profile merlin-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-application,Value=cicd-artifactory-edge-prod' --profile merlin-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-business,Value=Platform' --profile merlin-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-department,Value=Cloud Engineering - 431500' --profile merlin-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-owner,Value=techops-cicd' --profile merlin-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-product,Value=Host Platform' --profile merlin-sso --region us-gov-west-1; done
