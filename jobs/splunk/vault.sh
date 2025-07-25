#!/usr/bin/env bash

export VAULT_ADDR='https://secrets.splunkit.io'
export VAULT_NAMESPACE=mobile

export pass=$(security find-generic-password -l okta_pw -g 2>&1 1>/dev/null | cut -d'"' -f2)

if [[ -z $pass ]]; then
  echo && echo "Please make sure you've added your Okta password to macOS Keychain." && exit 1
fi

type brew
 if [[ $? -ne 0 ]]
 then
   echo && echo "brew not found. Please install at http://brew.sh" && exit 1
 else
   echo && echo "brew already installed..." && echo
 fi

type vault
 if [[ $? -ne 0 ]]
 then
   echo && echo "Vault CLI not found. Installing via Brew..."
   brew install vault
 else
   echo && echo "Vault already installed." && echo
 fi

echo "Logging into Vault..."
echo "Please remember to update your Okta Password in Keychain if you changed it recently." && echo

expect << EOF
 spawn vault login -method=okta username=$USER -namespace=mobile
 expect "Password (will be hidden): "
 send "$pass\r"
 sleep 30
EOF

export VAR=$(vault kv get -ns=mobile -field=ANDROID_FT_TEST_HOST kv/android/gitlab)
echo $VAR
