#!/bin/sh
#
# Ilan Erenstein
# Version:  1.0
#
# Changelog:
# - 05/24/2012 -- Initial version of the script.
# - 06/12/2012 -- Now script uses hostnames.
#
# This script will setup install Spacewalk for the first time.
#

if [ `hostname |grep tul > /dev/null 2>&1; echo $?` -eq 0 ]; then
	SERVER="tul1itpswpxy01"
elif [ `hostname |grep lux > /dev/null 2>&1; echo $?` -eq 0 ]; then
	SERVER="lux2itpswpxy01"
elif [ `hostname |grep sjc  > /dev/null 2>&1; echo $?` -eq 0 ] || [ `hostname |grep sjc > /dev/null 2>&1; echo $?` -eq 0 ] || [ `hostname |grep amgsj > /dev/null 2>&1; echo $?` -eq 0 ]; then
	SERVER="sjc1itpswpxy01"
else 
	SERVER="tul1itpswpxy01"
fi

if [ -f /etc/yum.repos.d/5Server* ]; then
     rm -rf /etc/yum.repos.d/5Server*
fi

if [ -f /etc/sysconfig/rhn/systemid ]; then
     rm -rf /etc/sysconfig/rhn/systemid
fi

wget -O /tmp/spacewalk-deploy.sh http://$SERVER/pub/spacewalk-deploy.sh
chmod +x /tmp/spacewalk-deploy.sh
/tmp/spacewalk-deploy.sh
yum -y update rhncfg* rhnsd* osad
yum -y remove logwatch
service rhnsd restart
service osad restart
