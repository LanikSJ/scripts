#!/usr/bin/env bash
# This script will terminate an EC2 in the specified account
# Usage: ec2t AccountName

# Variables
username=$(whoami)
export username

IFS=_
read -r -a account <<< "$1"
export NAME=${account[0]}
export ENVIRONMENT=${account[1]}
getawskeys=$(find ~/GitHub/ -iname get-aws-keys.py |sort -d |head -1)
export getawskeys
AWSACCTS=$(find ~/GitHub/ -iname aws-account-list.csv |sort -d |head -1)
export AWSACCTS
ARN_ACCOUNT=$(grep "$NAME" "$AWSACCTS" |grep "$ENVIRONMENT" |cut -d "," -f 3)
export ARN_ACCOUNT

# Make sure both required variables are present
if [[ -z $getawskeys ]]; then
  echo && echo "Move-AWS-Tools repo not found. Check repo path and try again! "
  echo "Repo should be checked out somewhere under ~/GitHub " && exit 1
elif [[ -z $AWSACCTS ]]; then
  echo && echo "aws-accounts repo not found. Check repo path and try again! "
  echo "Repo should be checked out somewhere under ~/GitHub " && exit 1
fi

# Make sure there's a valid Account Number
if [[ -z $ARN_ACCOUNT ]]; then
  echo && echo "Account Number is blank. Check aws-accounts repo path and try again! "
  echo "Repo should be checked out in ~/GitHub/aws-accounts/ " && exit 1
fi

# Get AWS Keys
if [[ $1 == *"dev"* ]]; then
  export role="User"
elif [[ $1 == *"qa"* ]] || [[ $1 == *"prod"* ]]; then
  echo && echo "Thou shall not launch instances in QA/Prod. Please try again! " && exit 1
fi

if [[ -z $role ]]; then
  echo && echo "AWS Role is blank. Please try again! " && exit 1
fi

if ! "$getawskeys" -u "$username" -r "$role" -p "${1}"; then
  echo "AWS Auth failed check script path or permissions and try again! "
  echo "Repo should be checked out in ~/GitHub/Move-AWS-tools/ " && exit 1
fi

# Get Instance ID
INSTANCE_ID=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters Name=instance-state-name,Values=running Name=tag:Name,Values="$username"-test --output text)
export INSTANCE_ID

# If no instances left no need to go any further
if [[ -z ${INSTANCE_ID} ]]; then
  echo && echo -e "No instances left to terminate! " && exit 1
else
  # Terminate Instance
  echo && echo "Terminating Instance ..."
  aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}" 2>&1

  # Wait for all instances to die
  echo && echo "Waiting for the instance to die ..."
  if aws ec2 wait instance-terminated --instance-ids "${INSTANCE_ID}"; then
    echo && echo -e "Ok - ec2 instance terminated"
  else
    echo -e "Instance doesn't exist, nothing to terminate! "
  fi
fi
