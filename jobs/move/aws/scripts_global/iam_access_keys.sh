#!/usr/bin/env bash

for i in $(aws iam list-users --query Users[].UserName --output text |xargs -n1); do aws iam list-access-keys --user-name $i --query AccessKeyMetadata[].AccessKeyId --output text; done
