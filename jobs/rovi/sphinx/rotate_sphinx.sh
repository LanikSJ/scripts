#!/bin/bash

# Check for lock file
if [ -f /var/lock/sphinxlockfile ]; then
	# Make sure its owned by sphinx
	/bin/chown sphinx:sphinx /var/lock/sphinxlockfile
else 
	# Create the file if it doesn't exist
	/bin/touch /var/lock/sphinxlockfile && /bin/chown sphinx:sphinx /var/lock/sphinxlockfile
fi
# Check what user is running the script
if [ "$(id -u)" != "5111" ]; then 
   echo "*****                                              *****" 1>&2
   echo "*****      This script must be run as sphinx!      *****" 1>&2
   echo "*****      This script will sudo to sphinx now!    *****" 1>&2
   echo "*****                                              *****" 1>&2
# Add a pause so the above text can be read
	function pause(){
   	read -p "$*"
	}
   pause "***** Press any key to continue or Ctrl+C to exit  *****" 1>&2
# sudo to sphinx and run the command
   /usr/bin/sudo /bin/su - sphinx -c "/usr/bin/flock -n -x /var/lock/sphinxlockfile -c '/var/lib/sphinx/bin/indexer --config /var/lib/sphinx/etc/sphinx.conf --all --rotate'"
else
# Otherwise run the command normally
   /usr/bin/flock -n -x /var/lock/sphinxlockfile -c '/var/lib/sphinx/bin/indexer --config /var/lib/sphinx/etc/sphinx.conf --all --rotate'
fi
