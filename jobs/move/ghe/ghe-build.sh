#!/usr/bin/env bash
set -euo pipefail

# Function to select the GHE role
select_role() {
    PS3='Select an Option and Press Enter or Ctrl + C to Quit: '
    options=("Primary" "Standby")
    select opt in "${options[@]}"
    do
        case $opt in
            "Primary")
                role='primary'
                break
                ;;
            "Standby")
                role='standby'
                break
                ;;
            *)
                echo "Invalid option please try again!" >&2
                exit 1
                ;;
        esac
    done
    export role
}

# Function to get GHE version
get_ghe_version() {
    local version_input
    while true; do
        echo -n "What is the GHE you're building? (no dots / dashes /etc) "
        read -r version_input
        if [[ "$version_input" =~ [.-] ]]; then
            echo "Invalid input: Version should not contain dots or dashes. Please try again." >&2
        else
            version="$version_input"
            break
        fi
    done
    export version
}

# Function to get AWS region
get_aws_region() {
    local region_input
    echo -n "Enter the AWS region (e.g., us-west-2): "
    read -r region_input
    export REGION="$region_input"
}

# Main script execution
select_role
get_ghe_version
get_aws_region

# Define tags
declare -a TAGS=(
    "Key=Name,Value=github-$version-$role.moveaws.com."
    "Key=component,Value=GitHub"
    "Key=product,Value=internal_tools"
    "Key=owner,Value=syseng@move.com"
    "Key=environment,Value=prod"
)

# Convert tags array to a format suitable for AWS CLI
format_tags() {
    local formatted_tags=""
    for tag in "${TAGS[@]}"; do
        local key
        key=$(echo "$tag" | cut -d',' -f1 | cut -d'=' -f2)
        local value
        value=$(echo "$tag" | cut -d',' -f2 | cut -d'=' -f2)
        formatted_tags+="{\"Key\":\"$key\",\"Value\":\"$value\"},"
    done
    # Remove trailing comma
    echo "${formatted_tags%,}"
}

TAG_SPECIFICATIONS="ResourceType=instance,Tags=[$(format_tags)] ResourceType=volume,Tags=[$(format_tags)]"

echo "Fetching latest AMI for GitHub Enterprise..."
# Find latest AMI to use using jq for robust parsing
declare LATEST_AMI
LATEST_AMI=$(aws ec2 describe-images \
    --filter "Name=name,Values=GitHub Enterprise*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region "$REGION" \
    --output text)

if [ -z "$LATEST_AMI" ]; then
    echo "Error: Could not find a suitable AMI." >&2
    exit 1
fi

echo "LATEST AMI: $LATEST_AMI"

echo "Running EC2 instance..."
aws ec2 run-instances \
    --image-id "$LATEST_AMI" \
    --instance-type r4.2xlarge \
    --key-name aws-us-west-2-move \
    --security-group-ids sg-cce642a8 \
    --subnet-id subnet-a4e67dd3 \
    --tag-specifications "$TAG_SPECIFICATIONS"
