#!/bin/bash

FILE="/tmp/actweb-sync"

echo "Script started on `date` "

# Check lock file
if [ -f $FILE ]; then echo "ACTWEB Sync still running on `date`." && exit 1
	# Create lock file
	else touch "$FILE"
fi

# rsync ACTWEB site data
rsync -avhpre ssh --progress --stats --delete actweb:/www-data/ /www-data/ 2> /tmp/error.txt
if [ "$?" = "0" ]; then
	echo "ACTWEB Web sync completed."
else
	mail -s "ACTWEB Web sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# rsync Apache settings
rsync -avhpre ssh --progress --stats --delete actweb:/etc/httpd/conf.d/*.conf /etc/httpd/conf.d/ 2> /tmp/error.txt
if [ "$?" = "0" ]; then
        echo "ACTWEB Apache sync completed."
else
        mail -s "ACTWEB Apache sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# rsync web MySQL
rsync -avhpre ssh --progress --stats --delete actweb:/var/lib/mysql/actiance* /var/lib/mysql/ 2> /tmp/error.txt
if [ "$?" = "0" ]; then
	echo "ACTWEB Web MySQL sync completed." 
else
	mail -s "ACTWEB Web MySQL sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# rsync MySQL
rsync -avhpre ssh --progress --stats --delete actweb:/var/lib/mysql/mysql /var/lib/mysql/ 2> /tmp/error.txt
if [ "$?" = "0" ]; then
	echo "ACTWEB Web sync completed." 
else
	mail -s "ACTWEB Web sync failed" -r techops@actiance.com techops@actiance.com < /tmp/error.txt
fi

# Restart MySQL
/etc/init.d/mysqld restart
if [ "$?" = "0" ]; then
	echo "ACTWEB MySQL reload completed." 
else
	echo "MySQL restart on `hostname` failed!" | mail -s "ACTWEB MySQL reload failed" -r techops@actiance.com techops@actiance.com
fi

echo "Script finished on `date` " && echo " "

# Remove lock file
rm -rf $FILE
