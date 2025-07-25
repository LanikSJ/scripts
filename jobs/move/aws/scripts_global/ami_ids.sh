#!/usr/bin/env bash

amiid=ami-69eb2811
aws ec2 describe-instances |grep $amiid
