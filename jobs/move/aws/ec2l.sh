#!/usr/bin/env bash
# This script will launch an EC2 in the specified account
# Usage: ./script AccountName

export INSTANCE_SIZE='t3.micro'
export SUBNET='Private-A'
export SG='-sg-private*'

IFS=_ read -a account <<< "$1"
export NAME=${account[0]}
export ENVIRONMENT=${account[1]}
export getawskeys=$(find ~/GitHub/ -iname get-aws-keys.py |sort -d |head -1)
export AWSACCTS=$(find ~/GitHub/ -iname aws-account-list.csv |sort -d |head -1)
export ARN_ACCOUNT=$(grep $NAME $AWSACCTS |grep $ENVIRONMENT |cut -d "," -f 3)
export NAME_TAG="Key=Name,Value=$USER-test"
export COMPONENT_TAG="Key=component,Value=test"
export PRODUCT_TAG="Key=product,Value=move"
export OWNER_TAG="Key=owner,Value=ilan.erenstein@move.com"
export ENV_TAG="Key=environment,Value=dev"
export INSTANCE_TAG="ResourceType=instance,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}]"
export VOLUME_TAG="ResourceType=volume,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}]"
export TAGS="$INSTANCE_TAG $VOLUME_TAG"

# Menu
PS3='Select an Option and Press Enter or Ctrl + C to Quit: '
options=("Move-CentOS7" "Move-AMZN-ECS" "AMZN-ECS-Linux-2" "Market-CentOS7")
select opt in "${options[@]}"
do
  case $opt in
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
    *) echo && echo "Invalid option please try again!" && exit 1 ;;
  esac
done

# Functions
upper() {
  echo $NAME | tr '[:lower:]' '[:upper:]'
}

lower() {
  echo $NAME | tr '[:upper:]' '[:lower:]'
}

vpc_id() {
  aws ec2 describe-vpcs  --query 'Vpcs[].VpcId' --filters Name=tag:Name,Values=$NAME* --output text
}

ssh_key() {
  aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --filters Name=key-name,Values=aws-us-west-2-$NAME* --output text |awk '{print $1}'
}

subnet() {
  aws ec2 describe-subnets --filters Name=tag:Name,Values=$SUBNET Name=vpc-id,Values=$VPCID --query 'Subnets[].SubnetId' --output text
}

sg() {
  aws ec2 describe-security-groups --query SecurityGroups[].GroupId --filter Name=vpc-id,Values=$VPCID Name=tag:Name,Values=$SG --output text
}

base_ami() {
  aws ec2 describe-images --filter "Name=name,Values=$AMI_NAME*" --query "reverse(sort_by(Images[],&CreationDate))[*].[ImageId]" --output text |head -1
}

instance_map() {
  aws ec2 run-instances --image-id $LATEST_BASE_AMI --instance-type $INSTANCE_SIZE --key-name $SSHKEY --security-group-ids $SGID \
    --subnet-id $SUBNETID --block-device-mappings file:///tmp/mapping.json --query Instances[].InstanceId --tag-specifications ${TAGS} --output text
}

instance_nomap() {
  aws ec2 run-instances --image-id $LATEST_BASE_AMI --instance-type $INSTANCE_SIZE --key-name $SSHKEY --security-group-ids $SGID \
    --subnet-id $SUBNETID --query Instances[].InstanceId --tag-specifications ${TAGS} --output text
}

# Make sure there's a valid Account Name
if [[ -z $NAME ]]; then
  echo && echo "Account NAME is blank. Please try again! " && exit 1
fi

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
  echo "Repo should be checked out somewhere under ~/GitHub " && exit 1
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

$getawskeys -u $USER -r $role -p ${1}
if [[ $? != "0" ]]; then
  echo "AWS Auth failed check script path or permissions and try again! "
  echo "Repo should be checked out somewhere under ~/GitHub " && exit 1
fi

# Get VPC ID
export VPCID=$(vpc_id)

if [[ -z $VPCID ]]; then
  export NAME=$(upper)
  export VPCID=$(vpc_id)
fi

if [[ -z $VPCID ]]; then
  echo && echo "VPCID is blank. Please try again! " && exit 1
else
  echo && echo "VPCID = $VPCID" && export NAME=$(lower)
fi

# Get Subnet ID
export SUBNETID=$(subnet)

if [[ -z $SUBNETID ]]; then
  echo && echo "SUBNETID is blank. Please try again! " && exit 1
else
  echo "SUBNETID = $SUBNETID"
fi

# Get Security Group ID
export SGID=$(sg)

if [[ -z $SGID ]]; then
  echo && echo "SGID is blank. Please try again! " && exit 1
else
  echo "SGID = $SGID"
fi

# Get SSH KeyName
export SSHKEY=$(ssh_key)

if [[ -z $SSHKEY ]]; then
  echo && echo "SSHKEY is blank. Please try again! " && exit 1
else
  echo "SSHKEY = $SSHKEY"
fi

# Determine the most recent Base AMI:
export LATEST_BASE_AMI=$(base_ami)

if [[ -z $LATEST_BASE_AMI ]]; then
  echo && echo "LATEST BASE AMI is blank. Please try again! " && exit 1
else
  echo "LATEST Selected AMI = $LATEST_BASE_AMI"
fi

# Create EBS Mappings File
cat > /tmp/mapping.json <<EOF
[
  {
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "DeleteOnTermination": true,
      "VolumeSize": 10,
      "VolumeType": "gp2"
    }
  }
]
EOF

# Start new instance based on selected values
if [[ $AMI_NAME == "amzn-ecs-hvm" ]]; then
  export INSTANCE_ID=$(instance_nomap)
else
  export INSTANCE_ID=$(instance_map)
fi

if [ -z ${INSTANCE_ID} ]; then
  echo -e "Creation of ec2 instance failed! " && exit 1
else
  echo && echo -e "OK - EC2 Instance Launched"
fi

# Wait until the EC2 enters a running state
echo && echo "Waiting for ${INSTANCE_ID} to enter running state"
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID}

# Figure out IP and DNS
export IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
export DNSNAME=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[*].Instances[*].PrivateDnsName' --output text)

# Print all the values gathered so far
echo "IP Address = " $IP
echo "DNS NAME = " $DNSNAME
echo "SSH KeyName = " $SSHKEY
echo "Instance ID = " $INSTANCE_ID

# Cleanup
rm -rf /tmp/mapping.json
