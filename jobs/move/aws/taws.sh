#!/usr/bin/env bash
# This script will tag AWS AMIs as baked.
# Usage: ./script AMIID

# Check if an AMI exists
aws ec2 describe-images --image-ids "$@" &>/dev/null
if [ "$?" != "0"  ]; then
  echo -e "$@ doesn't exist! " && exit 1
else
  echo -e "$@ Found!" && echo && echo -e "Taging..."
  # Add tags to the instance
  aws ec2 create-tags --resources "$@" --tags 'Key=baked,Value=true'
  if [ "$?" = "0"  ]; then
    echo && echo -e "Done! " && exit 0
  else
    echo && echo -e "Failed! "
  fi
fi
