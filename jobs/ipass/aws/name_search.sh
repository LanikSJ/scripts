#!/usr/bin/env bash
# Usage: ./name_search.sh region hostname

ec2-describe-instances --region $1 --filter "tag-value=$2" |awk '{print $4}' |grep ec2-
