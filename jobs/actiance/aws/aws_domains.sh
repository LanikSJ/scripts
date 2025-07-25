#!/usr/bin/env bash

route53 ls |grep Name |awk '{print $3}' |sort -d
