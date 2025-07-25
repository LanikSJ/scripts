#!/bin/sh

# Variables
dir="/home"
user="ls -l $dir |awk '{print $9}'"

echo -e "Check if $dir is empty..."
if [ "$( ls -A $dir )" ]; then echo -e "Home directories located!\n" && echo -e "Renaming Ray Casaclang home directory" && mv -f $dir/rayc $dir/rcasaclang
                if [ "$?" = "0" ]; then echo -e "Done!\n"
                        else echo -e "Home directory for Ray Casaclang doesn't exist!!\n"
                fi
        echo -e "Changing user/group permissions on home directories....\n"
        for username in $( ls -l $dir | awk '{print $9}' ); do chown -R $username $dir/$username && chmod 750 $dir/$username
                        if [ "$?" = "0" ]; then echo -e "User permissions for $username are Done!"
                                else echo -e "Failed to change user permissions for $username! $username doesn't exist."
                        fi
                groupname=`id -gn $username` && chgrp -R $groupname $dir/$username
                        if [ "$?" = "0" ]; then echo -e "Group permissions for $username are Done!"
                                else echo -e "Failed to change group permissions for $username! $username doesn't exist."
                        fi
        done
else echo -e "$dir is empty!"
fi
