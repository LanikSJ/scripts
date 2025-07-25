#!/bin/bash
if grep -qs '/staging' /proc/mounts; then
umount /staging
fi

mkdir -p /staging
rhncfg-client get /etc/nagios/nrpe.cfg
service nrpe restart

if [ `alias |grep cp > /dev/null 2>&1; echo $?` -eq 0 ]; then
unalias cp
fi

if [ `hostname |grep tul > /dev/null 2>&1; echo $?` -eq 0 ]; then
BUILD="10.202.51.32"
elif [ `hostname |grep lux > /dev/null 2>&1; echo $?` -eq 0 ]; then
BUILD="10.110.212.14"
elif [ `hostname |grep scl > /dev/null 2>&1; echo $?` -eq 0 ] || [ `hostname |grep sjc > /dev/null 2>&1; echo $?` -eq 0 ] || [ `hostname |grep amgsj > /dev/null 2>&1; echo $?` -eq 0 ]; then
BUILD="10.28.208.20"
else
BUILD="10.202.51.32"
fi

if [ `cat /var/spool/cron/root |grep hp_disk > /dev/null 2>&1; echo $?` -ne 0 ]; then
echo "00 */1 * * * /usr/sbin/hp_disk.sh > /var/log/hp_disk_check.log" >> /var/spool/cron/root
fi

mount -o ro,soft,nolock $BUILD:/var/linux/redhat/misc/6Server/scripts/ /staging
cp /staging/HP/hp_disk.sh /usr/sbin/
chmod 700 /usr/sbin/hp_disk.sh
umount /staging