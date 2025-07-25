#!/usr/bin/env bash
# Set hostname correctly 

echo "Current hostname is `hostname`."

if [ "$HOSTNAME" != ilan-mac.corp.ipass.com ]; then
	sudo hostname ilan-mac.corp.ipass.com
	echo "Changed hostname to `hostname`."
else echo "Hostname already set!"
fi
