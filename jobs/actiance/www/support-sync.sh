#!/bin/bash

FILE="/tmp/support-sync"

echo "Script started on `date` "

# Check for lock file
if [ -f $FILE ]; then echo "Support Sync still running on `date`." && exit 1
	# Create lock file
	else touch "$FILE"
fi

# rsync Support site data
rsync -avprhe ssh --progress --stats --delete support1:/data/www/ /data/www/ --exclude-from=/usr/local/sbin/exclude.txt 2> /tmp/error.txt
if [ "$?" = "0" ]; then
	echo "Support Web sync completed." 
else
	mail -s "Support Web sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# rsync Apache settings
rsync -avprhe ssh --progress --stats --delete support1:/etc/httpd/conf.d/*.conf /etc/httpd/conf.d/ --exclude=backup 2> /tmp/error.txt
if [ "$?" = "0" ]; then
	echo "Support Apache sync completed."
else
	mail -s "Support Apache sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# reload Apache
/etc/init.d/httpd reload
if [ "$?" = "0" ]; then
	echo "Support Apache reload completed." 
else
	echo "Apache reload on `hostname` failed!" | mail -s "Support Apache reload failed" -r techops@actiance.com techops@actiance.com
fi

echo "Script finished on `date` " && echo " "

# Remove lock file
rm -rf $FILE
