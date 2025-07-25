#!/bin/bash

if grep -qs '/staging' /proc/mounts; then
	umount /staging
fi

mkdir -p /staging
yum -y remove mysql-libs
mount -o ro,soft,nolock 10.110.212.14:/var/linux/software /staging
if [ `rpm -q --queryformat '%{VERSION}' redhat-release` = 5Server ]; then rpm -ivh /staging/MySQL/EL5/MySQL-server*.rpm /staging/MySQL/EL5/MySQL-client*.rpm /staging/MySQL/EL5/MySQL-shared-compat*.rpm
elif [ `rpm -q --queryformat '%{VERSION}' redhat-release-server` = 6Server ]; then rpm -ivh /staging/MySQL/EL6/MySQL-server*.rpm /staging/MySQL/EL6/MySQL-client*.rpm /staging/MySQL/EL6/MySQL-shared-compat*.rpm
else echo "This is not RHEL5/6 Server"
fi

chkconfig mysql on
service mysql start
yum -y install php-mysql
umount /staging