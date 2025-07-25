#!/usr/bin/env bash
# This script will run a script on all AWS Accounts
# Borrowed HEAVILY from Ben K's "global runner"
# Usage: ./script FileName

# Variables
export getawskeys=$(find ~/GitHub -iname get-aws-keys.py |sort -d |head -1)
export acctslist=$(find ~/GitHub -iname aws-account-list.csv |sort -d |head -1)
export moveawstools=$(find ~/GitHub -iname move-aws-tools |sort -d |head -1)
export awsaccts=$(find ~/GitHub -iname aws-accounts |sort -d |head -1)

# Set File and PATH Location
FILE=$1
DIR=$PWD

# Check for if File is passed
if [ -z "$1" ]; then
  echo "You must provide a shell script to run across all accounts." && exit 1;
fi

if [ ! -f "$FILE" ]; then
  echo && echo "You must provide a shell script file to run across all accounts." && exit 1;
fi

# Check if variables are present
if [[ -z $getawskeys ]]; then
  mkdir -p ~/GitHub/ && git clone --depth 1 git@github.move.com:IT-Operations/Move-AWS-Tools.git ~/GitHub/
  export getawskeys="~/GitHub/Move-AWS-Tools/get-aws-keys.py"
else
  echo && echo "Pulling latest copy of Move-AWS-Tools" && cd $moveawstools && git pull && cd $DIR
fi

if [[ -z $acctslist ]]; then
  mkdir -p ~/GitHub/ && git clone --depth 1 git@github.move.com:IT-Operations/aws-accounts.git ~/GitHub/
  export acctslist="~/GitHub/aws-accounts/aws-account-list.csv"
else
  echo && echo "Pulling latest copy of aws-accounts" && cd $awsaccts && git pull && cd $DIR
fi

# More Variables to Declare
declare -a account_id
declare -a account_name
declare -a account_environment

# Read in the Accounts List
ii=1

while IFS=$',' read -r accountName environment accountID
do
  account_id[$ii]=$accountID
  account_name[$ii]=$accountName
  account_environment[$ii]=$environment
  ii=$ii+1
done < "$acctslist"

for aid in ${account_id[@]}
do
  al="$al, \"$aid\""
done

al="${al:2}"

for key in ${!account_id[@]};
do
  echo ""
  echo "-----------------------------------------------------------------------------"
  echo "AccountID: ${account_id[$key]} (${account_name[$key]}-${account_environment[$key]})"

  # Clear out existing AWS session environment, or the awscli call will fail
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN

  # Old ec2 tools use other env vars
  unset AWS_ACCESS_KEY AWS_SECRET_KEY AWS_DELEGATION_TOKEN

  ACCOUNT="${account_id[$key]}"
  ACCOUNTNAME="${account_name[$key]}_${account_environment[$key]}"
  ENVIRONMENT="${account_environment[$key]}"
  ACCOUNTLIST=${al}

  if [[ $ACCOUNTNAME == "infosec_dev" ]]; then
    ROLE="User"
  else
    ROLE="Move-SE"
  fi

  # Check for Accounts that have no Move-SE Role
  if [[ $ACCOUNTNAME == "move_backup" ]] ||
  [[ $ACCOUNTNAME == "move_qa" ]] ||
  [[ $ACCOUNTNAME == "rdc_local" ]]; then
    echo && echo "Skipping ..."
  else
    # Assume Role in Given Account
    $getawskeys -r $ROLE -p $ACCOUNTNAME

    # Run Script
    source $FILE
  fi
done
