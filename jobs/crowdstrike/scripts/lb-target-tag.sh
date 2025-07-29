#!/bin/bash

while IFS= read -r i; do aws elbv2 add-tags --resource-arns "$i" --tags Key=cstag-owner,Value=techops-cicd --profile csa --region us-west-2; done < "$1"
while IFS= read -r i; do aws elbv2 describe-tags --resource-arns "$i" --profile csa --region us-west-2; done < "$1"
