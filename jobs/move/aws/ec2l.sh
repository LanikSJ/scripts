#!/usr/bin/env bash
# This script will launch an EC2 in the specified account
# Usage: ./script AccountName

# Set script variables
username=$(whoami)
export username
export INSTANCE_SIZE='t3.micro'
export SUBNET='Private-A'
export SG='-sg-private*' # Security Group name pattern

# Parse account name and environment from the first argument
IFS=_ read -r -a account <<< "$1"
export NAME="${account[0]}"
export ENVIRONMENT="${account[1]}"

# Helper function to find a file
find_file() {
  local filename="$1"
  find ~/GitHub/ -iname "$filename" | sort -d | head -1
}

# Locate required scripts and data files
getawskeys=""
getawskeys=$(find_file "get-aws-keys.py")
export getawskeys
AWSACCTS=""
AWSACCTS=$(find_file "aws-account-list.csv")
export AWSACCTS

# Extract ARN account from the CSV
ARN_ACCOUNT=""
ARN_ACCOUNT=$(awk -F',' -v name="$NAME" -v env="$ENVIRONMENT" '$1 == name && $2 == env {print $3}' "$AWSACCTS")
export ARN_ACCOUNT

# Define instance and volume tags
export NAME_TAG="Key=Name,Value=${username}-test"
export COMPONENT_TAG="Key=component,Value=test"
export PRODUCT_TAG="Key=product,Value=move"
export OWNER_TAG="Key=owner,Value=ilan.erenstein@move.com"
export ENV_TAG="Key=environment,Value=dev"
export INSTANCE_TAG="ResourceType=instance,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}]"
export VOLUME_TAG="ResourceType=volume,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}]"
export TAGS="$INSTANCE_TAG $VOLUME_TAG"

# Menu for AMI selection
PS3='Select an Option and Press Enter or Ctrl + C to Quit: '
options=("Move-CentOS7" "Move-AMZN-ECS" "AMZN-ECS-Linux-2" "Market-CentOS7")
select opt in "${options[@]}"
do
  case "$opt" in
    "Move-CentOS7")
      export AMI_NAME='centos7-hvm'
      break
      ;;
    "Move-AMZN-ECS")
      export AMI_NAME='amzn-ecs-hvm'
      break
      ;;
    "AMZN-ECS-Linux-2")
      export AMI_NAME='amzn2-ami-ecs-hvm'
      break
      ;;
    "Market-CentOS7")
      export AMI_NAME='CentOS Linux 7 x86_64 HVM'
      break
      ;;
    *) error_exit "Invalid option. Please try again!" ;;
  esac
done

# --- Functions ---

# Function for consistent error messages and exiting
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Convert NAME to uppercase
upper() {
  echo "$NAME" | tr '[:lower:]' '[:upper:]'
}

# Convert NAME to lowercase
lower() {
  echo "$NAME" | tr '[:upper:]' '[:lower:]'
}

# Get VPC ID based on NAME tag
vpc_id() {
  aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --filters "Name=tag:Name,Values=${NAME}*" --output text
}

# Get SSH KeyName
ssh_key() {
  aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --filters "Name=key-name,Values=aws-us-west-2-${NAME}*" --output text | awk '{print $1}'
}

# Get Subnet ID
subnet() {
  aws ec2 describe-subnets --filters "Name=tag:Name,Values=${SUBNET}" "Name=vpc-id,Values=${VPCID}" --query 'Subnets[].SubnetId' --output text
}

# Get Security Group ID
sg() {
  aws ec2 describe-security-groups --query SecurityGroups[].GroupId --filter "Name=vpc-id,Values=${VPCID}" "Name=tag:Name,Values=${SG}" --output text
}

# Get the most recent Base AMI ID
base_ami() {
  aws ec2 describe-images --filter "Name=name,Values=${AMI_NAME}*" --query "reverse(sort_by(Images[],&CreationDate))[*].[ImageId]" --output text | head -1
}

# EBS Block Device Mapping JSON (using a here-string for clarity)
EBS_MAPPING_JSON='[
  {
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "DeleteOnTermination": true,
      "VolumeSize": 10,
      "VolumeType": "gp2"
    }
  }
]'

# Function to launch instance with EBS mapping
instance_map() {
  aws ec2 run-instances \
    --image-id "$LATEST_BASE_AMI" \
    --instance-type "$INSTANCE_SIZE" \
    --key-name "$SSHKEY" \
    --security-group-ids "$SGID" \
    --subnet-id "$SUBNETID" \
    --block-device-mappings "$EBS_MAPPING_JSON" \
    --query Instances[].InstanceId \
    --tag-specifications "${TAGS}" \
    --output text
}

# Function to launch instance without EBS mapping
instance_nomap() {
  aws ec2 run-instances \
    --image-id "$LATEST_BASE_AMI" \
    --instance-type "$INSTANCE_SIZE" \
    --key-name "$SSHKEY" \
    --security-group-ids "$SGID" \
    --subnet-id "$SUBNETID" \
    --query Instances[].InstanceId \
    --tag-specifications "${TAGS}" \
    --output text
}

# --- Script Execution Logic ---

# Validate Account Name
if [[ -z "$NAME" ]]; then
  error_exit "Account NAME is blank. Please provide a valid account name as the first argument."
fi

# Validate required file paths
if [[ -z "$getawskeys" ]]; then
  error_exit "Move-AWS-Tools repo (get-aws-keys.py) not found. Check repo path and ensure it's under ~/GitHub."
elif [[ -z "$AWSACCTS" ]]; then
  error_exit "aws-accounts repo (aws-account-list.csv) not found. Check repo path and ensure it's under ~/GitHub."
fi

# Validate Account Number
if [[ -z "$ARN_ACCOUNT" ]]; then
  error_exit "Account Number is blank. Check aws-accounts repo path and try again. Ensure the repo is under ~/GitHub."
fi

# Determine AWS Role based on environment
if [[ "$1" == *"dev"* ]]; then
  export role="User"
elif [[ "$1" == *"qa"* ]] || [[ "$1" == *"prod"* ]]; then
  error_exit "Launching instances in QA/Prod is not allowed. Please try again with a 'dev' account."
fi

if [[ -z "$role" ]]; then
  error_exit "AWS Role is blank. This should not happen. Please check script logic."
fi

# Get AWS Keys
if ! "$getawskeys" -u "$username" -r "$role" -p "${1}"; then
  error_exit "AWS authentication failed. Check script path or permissions for 'get-aws-keys.py' and try again. Ensure the repo is under ~/GitHub."
fi

# Get VPC ID
VPCID=$(vpc_id)
export VPCID

if [[ -z "$VPCID" ]]; then
  # Try with uppercase name if initial lookup failed
  NAME=$(upper)
  VPCID=$(vpc_id)
  export VPCID
fi

if [[ -z "$VPCID" ]]; then
  error_exit "VPCID is blank. Could not determine VPC ID for account '$NAME'. Please check AWS configuration."
else
  echo "VPCID = $VPCID"
  NAME=$(lower) # Reset NAME to original case after upper() call
fi

# Get Subnet ID
SUBNETID=""
SUBNETID=$(subnet)
export SUBNETID

if [[ -z "$SUBNETID" ]]; then
  error_exit "SUBNETID is blank. Could not determine Subnet ID for SUBNET '$SUBNET' in VPC '$VPCID'. Please check AWS configuration."
else
  echo "SUBNETID = $SUBNETID"
fi

# Get Security Group ID
export SGID=""
SGID=$(sg)

if [[ -z "$SGID" ]]; then
  error_exit "SGID is blank. Could not determine Security Group ID for pattern '$SG' in VPC '$VPCID'. Please check AWS configuration."
else
  echo "SGID = $SGID"
fi

# Get SSH KeyName
SSHKEY=""
SSHKEY=$(ssh_key)
export SSHKEY

if [[ -z "$SSHKEY" ]]; then
  error_exit "SSHKEY is blank. Could not determine SSH Key for account '$NAME'. Please check AWS configuration."
else
  echo "SSHKEY = $SSHKEY"
fi

# Determine the most recent Base AMI
LATEST_BASE_AMI=$(base_ami)
export LATEST_BASE_AMI

if [[ -z "$LATEST_BASE_AMI" ]]; then
  error_exit "LATEST BASE AMI is blank. Could not determine AMI for name pattern '$AMI_NAME'. Please check AWS configuration."
else
  echo "LATEST Selected AMI = $LATEST_BASE_AMI"
fi

# Start new instance based on selected values
if [[ "$AMI_NAME" == "amzn-ecs-hvm" ]]; then
  INSTANCE_ID=""
  INSTANCE_ID=$(instance_nomap)
else
  INSTANCE_ID=""
  INSTANCE_ID=$(instance_map)
fi
export INSTANCE_ID

if [[ -z "$INSTANCE_ID" ]]; then
  error_exit "Creation of EC2 instance failed! No instance ID returned."
else
  echo "OK - EC2 Instance Launched: $INSTANCE_ID"
fi

# Wait until the EC2 enters a running state
echo "Waiting for ${INSTANCE_ID} to enter running state..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}" || error_exit "EC2 instance did not enter running state within the expected time."

# Figure out IP and DNS
IP=""
IP=$(aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
export IP
DNSNAME=""
DNSNAME=$(aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" --query 'Reservations[*].Instances[*].PrivateDnsName' --output text)
export DNSNAME

# Print all the values gathered so far
echo "IP Address = $IP"
echo "DNS NAME = $DNSNAME"
echo "SSH KeyName = $SSHKEY"
echo "Instance ID = $INSTANCE_ID"
