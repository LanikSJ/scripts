#!/bin/sh
string=`ps -aef |grep httpd |wc -l`
if [ "$string" -ge "2" ]; then exit 0
         else exit 1
fi
