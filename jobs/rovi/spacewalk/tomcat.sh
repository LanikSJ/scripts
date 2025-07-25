#!/bin/bash
find / -name *manager |grep webapps |grep -v tmp |grep -v cache
if [ "$?" -eq "0" ]; then exit 5; fi
find / -name *manager |grep -i catalina |grep -v tmp |grep -v cache
if [ "$?" -eq "0" ]; then exit 5; fi