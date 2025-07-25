#!/bin/bash

#locate host-manager |grep webapps |grep '/host-manager' &> /dev/null || locate manager |grep webapps |grep '/manager' &> /dev/null
find / -name *manager |grep webapps

if [ "$?" -eq "0" ]; then 
	exit 5
fi

#locate host-manager |grep -i catalina |grep '/host-manager' &> /dev/null || locate manager |grep -i catalina |grep '/manager' &> /dev/null
find / -name *manager |grep -i catalina

if [ "$?" -eq "0" ]; then 
	exit 5
fi
