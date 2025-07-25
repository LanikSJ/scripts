#!/usr/bin/env bash

PS3='Select an Option and Press Enter or Ctrl + C to Quit: '
options=("Primary" "Standby")
select opt in "${options[@]}"
do
  case $opt in
        "Primary")
          export role='primary'
          break
          ;;
        "Standby")
          export role='standby'
          break
          ;;
        *) echo && echo "Invalid option please try again!" && exit 1;;
  esac
done

echo && echo -n "What is the GHE you're building? (no dots / dashes /etc) "
read version

export NAME_TAG="Key=Name,Value=github-$version-$role.moveaws.com."
export COMPONENT_TAG="Key=component,Value=GitHub"
export PRODUCT_TAG="Key=product,Value=internal_tools"
export OWNER_TAG="Key=owner,Value=syseng@move.com"
export ENV_TAG="Key=environment,Value=prod"

# Find latest AMI to use
export LATEST_AMI=$(aws ec2 describe-images --filter "Name=name,Values=GitHub Enterprise*" \
--query 'sort_by(Images[].{YMD:CreationDate,ImageId:ImageId},&YMD)|reverse(@)|[0]' --region $REGION --output text |awk '{print $1}')
echo "LATEST AMI: $LATEST_AMI"

aws ec2 run-instances --image-id $LATEST_AMI --instance-type r4.2xlarge --key-name aws-us-west-2-move --security-group-ids sg-cce642a8 --subnet-id subnet-a4e67dd3 --tag-specifications ResourceType=instance,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}] ResourceType=volume,Tags=[{$NAME_TAG},{$COMPONENT_TAG},{$PRODUCT_TAG},{$OWNER_TAG},{$ENV_TAG}]
