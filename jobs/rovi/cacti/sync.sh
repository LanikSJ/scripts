#!/bin/bash

HOST=`hostname -s`

if [ $HOST != sjc1itdcacti1 ]; then
	echo "This is not Cacti Dev Box, Bye Bye." && exit 1
else
	echo && echo "Script started on -- `date`."
	rsync -av --progress --delete --exclude-from=/home/ierenstein/scripts/cacti/exclusions.txt /home/ierenstein/ ierenstein@cacti:/home/ierenstein/ 
fi
