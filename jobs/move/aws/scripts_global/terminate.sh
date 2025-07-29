#!/usr/bin/env bash

# Check if username is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

username=$1

# Get Instance ID
INSTANCE_ID=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --filters Name=instance-state-name,Values=running Name=tag:Name,Values="$username"-test --output text)
export INSTANCE_ID

# If no instances left no need to go any further
if [[ -z ${INSTANCE_ID} ]]; then
  echo && echo -e "No instances left to terminate! "
else
  # Terminate Instance
  echo && echo "Terminating Instance ${INSTANCE_ID}"
  aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}" 2>&1
fi
