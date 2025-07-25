#!/usr/bin/env bash
pass=$( security find-generic-password -l ssh_login -g 2>&1 1>/dev/null | cut -d'"' -f2 )

echo "Creating Folders."
sshpass -p"$pass" ssh $1 "mkdir -p .ssh; chmod 700 .ssh; touch .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"
echo "Adding ssh keys."
cat ~/.ssh/id_rsa.pub | sshpass -p"$pass" ssh $1 "cat - >> .ssh/authorized_keys"
echo "Done."
