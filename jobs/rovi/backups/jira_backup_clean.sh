#!/bin/bash

logs="/jira/jira/logs"
backup="/jira/backup"
corrupted="/jira/backup/corrupted/"

if [ -d "$corrupted" ]; then
	echo "Removing corrupted folder from /jira/backups/ if it exists."
	rm -rf $corrupted > /dev/null
fi

echo "Removing old backups older then 90 days."
find $backup/*.zip -type f -mtime +90 -exec rm {} \; -print
if [ "$?" = "0" ]; then
	echo "All done now!!"
else
        echo -e "Backups can not be removed!!"
        exit 1
fi

echo "Removing old logs older then 90 days."
find $logs/*.log -type f -mtime +90 -exec rm {} \; -print
if [ "$?" = "0" ]; then
        echo "All done now!!"
else
        echo -e "Logs can not be removed!!"
        exit 1
fi
