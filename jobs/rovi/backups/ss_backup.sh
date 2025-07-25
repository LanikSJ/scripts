#!/bin/bash

DATE=$(date +"%Y%m%d")
HOME=$"/local/SiteScope/groups"
BACKUP=$"/root/ss-backups"

echo "Removing unneeded backup files"
find $HOME/*.bak -type f -exec rm {} \; -print
echo "Zipping groups directory in SiteScope"
tar czplvf $BACKUP/groups.$DATE.tgz $HOME 
echo "Removing backups older then 10 days"
find $BACKUP/*.tgz -type f -mtime +10 -exec rm {} \;
echo "All done now!!"
