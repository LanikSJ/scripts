#!/bin/bash
if [ `ps -aef |grep nrpe |grep -v grep > /dev/null 2>&1; echo $?` -eq 0 ]; then
	rhncfg-client get /etc/nagios/nrpe.cfg
	service nrpe restart
elif [ `hostname -s` = sjc1nag01 ]; then
	exit 5
else
mv -f /etc/nagios/nrpe.cfg /tmp
mv -f /usr/lib/nagios/* /tmp
rm -rf /etc/nagios /usr/lib/nagios
echo "Nagios configuration removed"
fi
