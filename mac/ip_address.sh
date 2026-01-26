#!/bin/bash
# This script retrieves and displays the current public IP address of the machine.

# Use a more modern and direct service to get the public IP address.
# icanhazip.com returns only the IP address, simplifying parsing.
# Add error handling for robustness.

if IP_ADDRESS=$(curl -s https://icanhazip.com); then
  echo "✅ Current Public IP Address: $IP_ADDRESS"
else
  echo "❌ Failed to retrieve public IP address." >&2
  exit 1
fi
