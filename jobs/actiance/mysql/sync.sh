#!/bin/bash

DBS="accesscontrol	\
	spyware		\
	xblock_cerb	\
	xblock_com"

for i in $DBS; do rsync --progress --stats --delete -avhpre ssh mysql1:/data/mysql/$i/ /data/mysql/$i; done
