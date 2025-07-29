#!/bin/bash -l

set -ex

DAYS=30
REGION="us-west-2"
IMAGE_NAME="fe-property-services*"
TARGET_DATE=$(date --date="$DAYS day ago" +%Y-%m-%d)

# Use jq for robust JSON parsing
IMAGES=$(aws ec2 describe-images --filters Name=name,Values="$IMAGE_NAME" --query "Images[?CreationDate <= \`$TARGET_DATE\`].ImageId" --region "$REGION" --output text)

if [ -z "$IMAGES" ]; then
  echo "No AMIs found to deregister for image name '$IMAGE_NAME' older than '$TARGET_DATE' in region '$REGION'."
  exit 0
fi

echo "Found the following AMI IDs to deregister: $IMAGES"

# Iterate over each AMI ID and deregister
for i in $IMAGES; do
  echo "Deregistering AMI ID: $i in region $REGION..."
  # Uncomment the following line to actually deregister the AMI
  aws ec2 deregister-image --image-id "$i" --region "$REGION"
  echo "Deregistration command executed for $i. Please verify manually."
done

echo "Script finished."
