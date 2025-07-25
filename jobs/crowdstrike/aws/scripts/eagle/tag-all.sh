#!/bin/bash

for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-accounting,Value=cogs' --profile eagle-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-application,Value=cicd-artifactory-edge-prod' --profile eagle-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-business,Value=Platform' --profile eagle-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-department,Value=Cloud Engineering - 431500' --profile eagle-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-owner,Value=techops-cicd' --profile eagle-sso --region us-gov-west-1; done
for i in $(cat $1); do aws ec2 create-tags --resources $i --tags 'Key=cstag-product,Value=Host Platform' --profile eagle-sso --region us-gov-west-1; done
