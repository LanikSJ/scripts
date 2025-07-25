#!/bin/bash

DATE=$(date +"%Y%m%d-%H%M")
HOST='ftp.powweb.com'
USER='Slothpedcancer'
PASSWD='X[2aSg]67e[Q4r!u'
FILE="/backup/backup-$DATE.tgz"
PATH='/slothbkup'
PORT='2222'

PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

find /backup/backup-* -type f -mtime +30 -exec rm {} \; -print

tar czvvf $FILE /opt/Sloths/

lftp sftp://$USER:${PASSWD}@$HOST:$PORT -e "put $FILE; bye"
