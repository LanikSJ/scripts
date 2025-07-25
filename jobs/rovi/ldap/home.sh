#!/bin/bash
# This script changes permissions on users home directories according to the users uid/gid.

# Variables
dir="/home"

echo -e "Check if $dir is empty..."
if [ "$( ls -A $dir )" ]; then echo -e "Home directories located!\n"
	else echo -e "$dir is empty!"
fi

echo -e "Changing user/group permissions on home directories....\n"
#chown -R $user $dir/$user && chmod 700 $dir/$user
for user in $(ls -l $dir | awk '{print $9}'); do chown -R $user $dir/$user && chmod 700 $dir/$user; done
if [ "$?" = "0" ]; then echo -e "User permissions for $user are done.\n"
	else echo -e "Failed to change user permissions for $user!\n"
fi

#chgrp -R $group $dir/$user
for group in $(id -gn $user); do chgrp -R $group $dir/$user; done
if [ "$?" = "0" ]; then echo -e "Group permissions for $user are done.\n"
	else echo -e "Failed to change group permissions for $user!\n"
fi
