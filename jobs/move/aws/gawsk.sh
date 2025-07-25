#!/usr/bin/env bash
# This is a wrapper for CloudOps get-aws-keys.py script that passes a pre-defined username and an option for a custom role
# Script will assume that you have your GitHub folder in your home directory and Move-AWS-tools checked out under GitHub folder
# Otherwise run in Terminal: mkdir -p ~/GitHub; cd ~/GitHub; git clone https://github.move.com/IT-Operations/Move-AWS-Tools
# And then add the script in your $HOME/bin folder that will allow you to run it from any folder on your system

# Variables
export username=$(whoami)
export script="get-aws-keys.py"
export getawskeys=$(find ~/GitHub/ -iname $script)

# Functions
show_help() {
  echo "gawsk [options] - gets sts credentials and sets them as environment variables"
  echo " "
  echo "Options:"
  echo "-h, --help                        show brief help"
  echo "-l, --list                        list all configured accounts"
  echo "-r, --role RoleName               role name, (requires -p AccountName)"
  echo "-p, --profile AccountName         profile, uses Role: $role and username: $username"
  return 0
}

# Make sure the script is present
if [[ -z $getawskeys ]]; then
  echo "Unable to find location of your GitHub folder. Please correct! "
fi

# Commands
case "$1" in
  -l|--list)
    $getawskeys -l
    ;;
  -p|--profile)
    if [[ $2 == *"dev"* ]]; then
      export role="User"
    elif [[ $2 == *"qa"* ]] || [[ $2 == *"prod"* ]]; then
      export role="ReadOnly"
    fi
    $getawskeys -u $username -r $role -p $2
    ;;
  -r|--role)
    $getawskeys -u $username -r $2 -p $4
    ;;
  *|-h|--help)
    show_help
    ;;
esac
