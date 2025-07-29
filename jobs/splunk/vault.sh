#!/usr/bin/env bash

set -euo pipefail

export VAULT_ADDR='https://secrets.splunkit.io'
export VAULT_NAMESPACE='mobile'

# Retrieve Okta password from macOS Keychain
pass=$(security find-generic-password -l okta_pw -g 2>&1 1>/dev/null | cut -d'"' -f2 || true)

if [[ -z "$pass" ]]; then
    echo -e "\nPlease make sure you've added your Okta password to macOS Keychain."
    exit 1
fi

# Check if brew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo -e "\nbrew not found. Please install it from https://brew.sh"
    exit 1
else
    echo -e "\nbrew already installed...\n"
fi

# Check if vault CLI is installed
if ! command -v vault >/dev/null 2>&1; then
    echo -e "\nVault CLI not found. Installing via brew..."
    brew install vault
else
    echo -e "\nVault already installed.\n"
fi

echo "Logging into Vault..."
echo "Please remember to update your Okta Password in Keychain if you changed it recently."
echo

# Run 'vault login' with expect to handle interactive password input
expect <<EOF
    spawn vault login -method=okta username=$USER -namespace=mobile
    expect "Password (will be hidden): "
    send "$pass\r"
    expect eof
EOF

# Fetch secret from Vault
VAR=$(vault kv get -ns=mobile -field=ANDROID_FT_TEST_HOST kv/android/gitlab)

echo "$VAR"
