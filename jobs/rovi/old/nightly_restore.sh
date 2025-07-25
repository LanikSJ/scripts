#!/bin/bash
TODAY=$(date --date='1 day ago' +%Y-%m-%d)
echo "Downloading the backup"
wget https://backups.trymedia.com/databases/trygames/$TODAY.pgbackup-master.gz --http-user=backups --http-passwd='1w@ntb@ckup$' -O /tmp/$TODAY.pgbackup-master.gz
echo "Unziping the backup"
gunzip /tmp/$TODAY.pgbackup-master.gz
echo "Droping trygames and adserver databases"
psql -d template1 -c 'drop database trygames;'
psql -d template1 -c 'drop database adserver;'
echo "Dumping the backup into the database"
psql -U postgres -d template1 < /tmp/$TODAY.pgbackup-master
echo "Deleting the old backup"
rm -f /tmp/$TODAY.pgbackup-master
echo "Complete"
