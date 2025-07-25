#!/bin/bash

if grep -qs '/staging' /proc/mounts; then
	umount /staging
fi

mkdir -p /staging
if [ `alias |grep cp > /dev/null 2>&1; echo $?` -eq 0 ]; then unalias cp
fi

if [ `hostname | grep tul > /dev/null 2>&1; echo $?` -eq 0 ]; then
SERVER="10.202.51.32"
LOCATION="Tulsa"
elif [ `hostname | grep lux > /dev/null 2>&1; echo $?` -eq 0 ]; then
SERVER="10.110.212.14"
LOCATION="Luxembourg"
else
SERVER="10.202.51.32"
LOCATION="Tulsa"
fi

mount -o ro,soft,nolock $SERVER:/var/linux/redhat/misc/6Server/scripts/ /staging
if [ "$?" -eq 0 ]; then echo "$LOCATION Mounted"
else echo "Mount Failed" && exit 1
fi

if [ `hostname | grep srcapp > /dev/null 2>&1; echo $?` -eq 0 ]; then prog="recsd"
elif [ `hostname | grep srsapp > /dev/null 2>&1; echo $?` -eq 0 ]; then prog="solrd"
elif [ `hostname | grep srcmt > /dev/null 2>&1; echo $?` -eq 0 ]; then prog="cmtd"
else echo "This is not a Cluster App, Solr App or Cluster Manager" && exit 1
fi

if [ ! -f /etc/init.d/$prog ]; then echo "$prog didn't exist"
fi

cp /staging/SnR/$prog /etc/init.d/
chmod +x /etc/init.d/$prog
chkconfig $prog on
echo "Deployed $prog"
umount /staging
