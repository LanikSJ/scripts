#!/bin/bash

if grep -q '10.202.0.11' /etc/resolv.conf || grep -q '10.202.0.12' /etc/resolv.conf; then
RHEL5=`rpm -q --queryformat '%{VERSION}' redhat-release`
RHEL6=`rpm -q --queryformat '%{VERSION}' redhat-release-server`
else
	echo "This machine is not in Tulsa Armus" && exit 0
fi

if [ "$RHEL5" = "5Server" ]; then
	rhncfg-client get /etc/ldap.conf
	service nscd restart
elif [ "$RHEL6" = "6Server" ]; then
	rhncfg-client get /etc/ldap.conf /etc/nslcd.conf
	service nscd restart && service nslcd restart
else
	echo "This is not RHEL5/6 Server" && exit 0
fi
