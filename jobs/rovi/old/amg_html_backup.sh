#!/bin/sh

#DATE=$(date +"%Y%m%d")
HOME=$"/var/www/html"
BACKUP=$"/opt/dump"

echo "Tarballing and zipping the /var/www/html"
tar czpvf $BACKUP/amg_html_backup.tgz $HOME

echo Transferring to AMGMINT10...
echo "---------------------------------------------------"
echo "                Begin FTP Session  "
echo "---------------------------------------------------"
echo "open 144.198.80.20
      quote USER amgmint10
      quote PASS qua4pu
      verbose
      binary
      cd ftpdropbox
      put /opt/dump/amg_html_backup.tgz amg_html_backup.tgz
      close
      quit" |/usr/bin/ftp -n
echo "---------------------------------------------------"
echo "                End FTP Session  "
echo "---------------------------------------------------"

echo "Removing backups older then 10 days"
find $BACKUP/*.tgz -type f -mtime +10 -exec rm {} \; -print
echo "All done now!!"
