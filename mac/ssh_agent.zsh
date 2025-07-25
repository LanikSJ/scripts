#!/usr/bin/env zsh
# This script will load all the keys in your .ssh folder

export HOSTNAME=`hostname`
export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.$HOSTNAME.sock

# Check if SSH Agent is Running
AgentRunning=`ps -eaf | grep -i ssh-agent | grep -v grep | wc -l`
if [ $AgentRunning -lt 1 ]; then
	echo "No Agent! Cleaning up socks."
    rm -f $SSH_AUTH_SOCK >/dev/null
fi

# Load the Keys, the number should match how many keys you expect
AgentCount=`ssh-add -l | wc -l`
if [ $AgentCount -lt 3 ]; then
	ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
	for possiblekey in ${HOME}/.ssh/id_*; do
	if grep -q PRIVATE "$possiblekey"; then
		ssh-add "$possiblekey"
	fi
done
fi
