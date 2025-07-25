#!/bin/bash -l

ACCOUNT="860429940966"
AMI_TO_KEEP="10"
AMI_NAME="fe-property-services"
export REGION="us-west-2"

# If the script errors fail the job
set -e

# Clean up old AMIs
echo "Housekeeping: Deleting older AMIs..."

# Credentials
aws sts assume-role --role-arn=arn:aws:iam::${ACCOUNT}:role/User --role-session-name="userRole" --region $REGION > ${WORKSPACE}/credentials.txt

export AWS_SECRET_ACCESS_KEY=`grep SecretAccessKey ${WORKSPACE}/credentials.txt |cut -d"\"" -f4`
export AWS_SECURITY_TOKEN=`grep SessionToken ${WORKSPACE}/credentials.txt |cut -d"\"" -f4`
export AWS_ACCESS_KEY_ID=`grep AccessKeyId ${WORKSPACE}/credentials.txt |cut -d"\"" -f4`

set -x

# Get the number of AMIs
AMICOUNT=$(aws ec2 describe-images --filters Name=name,Values=$AMI_NAME* --query "sort_by(Images[].{YMD:CreationDate,ImageId:ImageId},&YMD)" --region $REGION | grep ImageId | wc -l)

# Get the number of AMIs to delete
RMCOUNT=`expr $AMICOUNT - $AMI_TO_KEEP`
echo "Number of AMIs to remove is $RMCOUNT"

if [ "${RMCOUNT}" -gt "0" ]; then
  # Get the oldest AMIs
  AMILIST=$(aws ec2 describe-images --filters Name=name,Values=$AMI_NAME* --query "sort_by(Images[].{YMD:CreationDate,ImageId:ImageId},&YMD)|[0:$rmcount]" --region $REGION | grep ImageId | cut -d"\"" -f4)

  # Delete the AMIs
  for AMI in `echo ${AMILIST}`;
  do
    aws ec2 deregister-image --image-id ${AMI} --region $REGION
  done
else
  echo "No AMIs to delete"
fi
