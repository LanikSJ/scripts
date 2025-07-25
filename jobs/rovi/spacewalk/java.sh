#!/bin/sh
string=`ps -aef |grep java |wc -l`
if [ "$string" -ge "2" ]; then exit 0
         else exit 1
fi
