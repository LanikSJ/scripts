#!/usr/bin/env bash
# This script will run a script on all AWS Accounts
# Borrowed HEAVILY from Ben K's "global runner"
# Usage: ./script FileName
# shellcheck disable=SC1090,SC2004

# Variables
export moveawstools="${HOME}/GitHub/Move-AWS-Tools"
export getawskeys="${moveawstools}/get-aws-keys.py"
export awsaccts="${HOME}/GitHub/aws-accounts"
export acctslist="${awsaccts}/aws-account-list.csv"

# Set File and PATH Location
FILE=$1

# Check for if File is passed
if [ -z "$1" ]; then
  echo "Error: You must provide a shell script to run across all accounts."
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: You must provide a valid shell script file to run across all accounts."
  exit 1
fi

# Ensure necessary repositories are cloned and up-to-date
if [ ! -d "$moveawstools" ]; then
  echo "Cloning Move-AWS-Tools..."
  mkdir -p "${HOME}/GitHub/" && git clone --depth 1 git@github.move.com:IT-Operations/Move-AWS-Tools.git "$moveawstools"
else
  echo "Pulling latest copy of Move-AWS-Tools..."
  pushd "$moveawstools" > /dev/null && git pull && popd > /dev/null || exit
fi

if [ ! -d "$awsaccts" ]; then
  echo "Cloning aws-accounts..."
  mkdir -p "${HOME}/GitHub/" && git clone --depth 1 git@github.move.com:IT-Operations/aws-accounts.git "$awsaccts"
else
  echo "Pulling latest copy of aws-accounts..."
  pushd "$awsaccts" > /dev/null && git pull && popd > /dev/null || exit
fi

# More Variables to Declare
declare -a account_id
declare -a account_name
declare -a account_environment

# Read in the Accounts List
ii=0 # Start index from 0 for bash arrays

while IFS=$',' read -r accountName environment accountID
do
  # Skip header row if present (assuming header is "accountName,environment,accountID")
  if [[ "$accountName" == "accountName" && "$environment" == "environment" && "$accountID" == "accountID" ]]; then
    continue
  fi
  account_id[$ii]=$accountID
  account_name[$ii]=$accountName
  account_environment[$ii]=$environment
  ii=$((ii+1))
done < "$acctslist"

# Construct the account list string for ACCOUNTLIST variable
al=""
first_account=true
for aid in "${account_id[@]}"
do
  if [ "$first_account" = true ]; then
    al="\"$aid\""
    first_account=false
  else
    al+=", \"$aid\""
  fi
done

for key in "${!account_id[@]}";
do
  echo ""
  echo "-----------------------------------------------------------------------------"
  echo "AccountID: ${account_id[$key]} (${account_name[$key]}-${account_environment[$key]})"

  # Clear out existing AWS session environment, or the awscli call will fail
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN

  # Old ec2 tools use other env vars
  unset AWS_ACCESS_KEY AWS_SECRET_KEY AWS_DELEGATION_TOKEN

  export ACCOUNT="${account_id[$key]}"
  export ACCOUNTNAME="${account_name[$key]}_${account_environment[$key]}"
  export ENVIRONMENT="${account_environment[$key]}"
  export ACCOUNTLIST="${al}" # Use the constructed string

  ROLE="Move-SE" # Default role
  if [[ "$ACCOUNTNAME" == "infosec_dev" ]]; then
    ROLE="User"
  fi

  # Check for Accounts that have no Move-SE Role
  case "$ACCOUNTNAME" in
    "move_backup"|"move_qa"|"rdc_local")
      echo "Skipping account: $ACCOUNTNAME"
      continue # Skip to the next iteration of the loop
      ;;
    *)
      # Assume Role in Given Account
      "${getawskeys}" -r "${ROLE}" -p "${ACCOUNTNAME}"

      # Run Script
      source "${FILE}"
      ;;
  esac
done
