#!/usr/bin/env zsh
# This script will update all the Python modules

export exclude="types-setuptools"

# Functions
python_module_upgrade() {
    if [[ -z $exclude ]]; then
      for i in $($python_version -m pip list --format=json |jq -r '.[].name'); do $python_version -m pip install -U $i; done
    else
      for i in $($python_version -m pip list --format=json |jq -r '.[].name' |grep -Ev $exclude); do $python_version -m pip install -U $i; done
    fi
}

echo && echo "Updating Python 3.12 Packages"
export python_version="python3.12"
python_module_upgrade

echo && echo "Updating Python 3.13 Packages"
export python_version="python3.13"
python_module_upgrade

