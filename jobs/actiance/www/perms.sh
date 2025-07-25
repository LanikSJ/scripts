#!/bin/bash

dir="webhelp	\
	usg	\
	filevault"
docs="webhelp"
support="usg	\
	filevault"

# Fix permissions
for i in $dir; do find /data/www/$i -type d -exec chmod 775 {} \; ; done
for i in $dir; do find /data/www/$i -type f -exec chmod 664 {} \; ; done
for i in $dir; do find /data/www/$i -name "*.sh" -type f -exec chmod 664 {} \; ; done
for i in $dir; do find /data/www/$i -name "*.pl" -type f -exec chmod 664 {} \; ; done

# Fix ownership
for i in $docs; do chown root.docs -R /data/www/$i; done
for i in $support; do chown root.support -R /data/www/$i; done
