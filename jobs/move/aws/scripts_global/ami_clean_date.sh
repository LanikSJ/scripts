#!/bin/bash -l

set -ex

DAYS=30
REGION="us-west-2"
IMAGE_NAME="fe-property-services*"
TARGET_DATE=$(date --date="$DAYS day ago" +%Y-%m-%d)

IMAGES=$(aws ec2 describe-images --filters Name=name,Values=$IMAGE_NAME --query "Images[?CreationDate <= \`$TARGET_DATE\`]" --region $REGION |grep ImageId |cut -d"\"" -f4)

echo "AMI IDs: $IMAGES"

for i in $IMAGES; do
  echo "Deregistering $i ... "
  echo "aws ec2 deregister-image --image-id $i --region $REGION"
  aws ec2 deregister-image --image-id $i --region $REGION
done
