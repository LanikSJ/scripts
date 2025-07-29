#!/bin/bash

# List of target hosts
hosts=("rhelupd1" "rhelupd2")

# Scripts to copy
scripts=(
  ~/scripts/ldap-client.sh
  ~/scripts/change_home_dir.sh
  ~/scripts/revert_ldap.sh
)

for host in "${hosts[@]}"; do
  echo "Copying scripts to $host..."
  if ! scp "${scripts[@]}" "${host}:"; then
    echo "Failed to copy scripts to $host"
  fi
done
