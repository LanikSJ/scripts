#!/usr/bin/env bash
# This is a wrapper for CloudOps get-aws-keys.py script that passes a pre-defined username and an option for a custom role
# Script will assume that you have your GitHub folder in your home directory and Move-AWS-tools checked out under GitHub folder
# Otherwise run in Terminal: mkdir -p ~/GitHub; cd ~/GitHub; git clone https://github.move.com/IT-Operations/Move-AWS-Tools
# And then add the script in your $HOME/bin folder that will allow you to run it from any folder on your system

# Variables
username=$(whoami)
# Define the expected location of Move-AWS-Tools
MOVE_AWS_TOOLS_DIR="$HOME/GitHub/Move-AWS-Tools"
GET_AWS_KEYS_SCRIPT="get-aws-keys.py"
getawskeys="$MOVE_AWS_TOOLS_DIR/$GET_AWS_KEYS_SCRIPT"

# Functions
show_help() {
  echo "gawsk [options] - gets sts credentials and sets them as environment variables"
  echo " "
  echo "Options:"
  echo "-h, --help                          show brief help"
  echo "-l, --list                          list all configured accounts"
  echo "-r, --role RoleName -p AccountName  role name and profile (e.g., -r Admin -p myaccount)"
  echo "-p, --profile AccountName           profile, uses Role: User (for dev) or ReadOnly (for qa/prod) and username: $username"
  return 0
}

# Make sure the script is present
if [[ ! -f "$getawskeys" ]]; then
  echo "Error: '$getawskeys' not found."
  echo "Please ensure 'Move-AWS-Tools' is checked out under '$HOME/GitHub/'."
  echo "Run in Terminal: mkdir -p ~/GitHub; cd ~/GitHub; git clone https://github.move.com/IT-Operations/Move-AWS-Tools"
  exit 1
fi

# Parse arguments
if [[ "$#" -eq 0 ]]; then
  show_help
  exit 0
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -l|--list)
      "$getawskeys" -l
      exit 0
      ;;
    -p|--profile)
      if [[ -z "$2" ]]; then
        echo "Error: --profile requires an argument (AccountName)."
        show_help
        exit 1
      fi
      profile_name="$2"
      # Use local for role if not needed outside this script
      if [[ "$profile_name" == *"dev"* ]]; then
        role="User"
      elif [[ "$profile_name" == *"qa"* ]] || [[ "$profile_name" == *"prod"* ]]; then
        role="ReadOnly"
      else
        # Default role if no specific match, or error if strict
        echo "Warning: No specific role defined for profile '$profile_name'. Defaulting to 'User'."
        role="User"
      fi
      "$getawskeys" -u "$username" -r "$role" -p "$profile_name"
      exit 0
      ;;
    -r|--role)
      if [[ -z "$2" ]]; then
        echo "Error: --role requires a role name."
        show_help
        exit 1
      fi
      role_name="$2"
      # Now check for -p and its argument
      if [[ -z "$3" || "$3" != "-p" ]]; then
        echo "Error: --role must be followed by -p AccountName."
        show_help
        exit 1
      fi
      if [[ -z "$4" ]]; then
        echo "Error: -p requires an account name."
        show_help
        exit 1
      fi
      profile_name="$4"
      "$getawskeys" -u "$username" -r "$role_name" -p "$profile_name"
      exit 0
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      show_help
      exit 1
      ;;
  esac
done
