#!/bin/bash

echo "Zipping mysql log files over 10 days old"
find /data/mysql5.0/storage/*.frm /data/mysql5.0/storage/*.MYD /data/mysql5.0/storage/*.MYI -type f -atime +10 \( -path '*gz' -prune -o -exec gzip {} \; \)
if [ "$?" = "0" ]; then
	echo "All done now!!"
else
        echo -e "Files don't exist!!"
        exit 1
fi
