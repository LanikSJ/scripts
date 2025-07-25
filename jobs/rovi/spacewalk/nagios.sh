#!/bin/bash

if grep -qs '/staging' /proc/mounts; then
	umount /staging
fi

mount -o ro,soft,nolock 10.202.51.32:/ks /staging
if [ `rpm -q --queryformat '%{VERSION}' redhat-release` = 5Server ]; then rpm -Uvh /staging/Utils/Nagios/EL5/x86_64/*.rpm
elif [ `rpm -q --queryformat '%{VERSION}' redhat-release-server` = 6Server ]; then rpm -Uvh /staging/Utils/Nagios/EL6/x86_64/*.rpm --nodeps
else echo "This is not RHEL5/6 Server" && exit 1
fi

chown -R nagios:nagios /usr/lib/nagios
chkconfig nrpe on
service nrpe restart
umount /staging