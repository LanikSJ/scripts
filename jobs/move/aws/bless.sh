#!/usr/bin/env bash
# This script will run bless from Move-AWS-tools repo.

# Variables
TOOLS=$(find "$HOME" -iname Move-AWS-tools | head -1)
export TOOLS

# Set IP based on location Office vs VPN
if ifconfig | grep inet | grep -q 10.238; then
  export IP="10.0.0.0/8" && echo "Blessing Office IP"
elif ifconfig | grep inet | grep -q 192.168.232; then
  export IP="192.168.0.0/16" && echo "Blessing VPN IP"
fi

# Execute Bless Client
cd "$TOOLS" && git pull
./bless_client.py us-west-2 "$USER" "$IP" centos
cd || exit
