#!/bin/sh
#
# Ilan Erenstein 06/01/2010
# Version:  1.10
#
# Changelog:
#
# 06/01/2010 -- Changed the copy from bath to /root/backup
#
# This script will revert LDAP client installation changes to OpenLDAP.
#

# Enviroment variables
#date=$(date "+%Y%m%d_%H%M")
backup="/root/backup"
dir="/home"

USERID=`id -u`
if [ "$USERID" -ne 0 ]; then echo -e "Sorry, You must be root to run this script." && exit 1 fi

# Add a pause so the above text can be read
        function pause(){
        read -p "$*"
        }

echo -e "Restoring /etc/issue"
cp -f $backup/issue /etc/issue
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/issue backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/ssh/sshd_config" 
cp -f $backup/sshd_config /etc/ssh/sshd_config
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/ssh/sshd_config backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/mail/sendmail.cf" 
cp -f $backup/sendmail.cf /etc/mail/sendmail.cf
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/mail/sendmail.cf backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/mail/submit.cf" 
cp -f $backup/submit.cf /etc/mail/submit.cf
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/mail/submit.cf backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/aliases" 
cp -f $backup/aliases /etc/aliases
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/aliases backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/ldap.conf" 
cp -f $backup/ldap.conf /etc/ldap.conf
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/ldap.conf backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/nsswitch.conf" 
cp -f $backup/nsswitch.conf /etc/nsswitch.conf
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/nsswitch.conf backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/pam.d/system-auth" 
cp -f $backup/system-auth /etc/pam.d/system-auth
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/pam.d/system-auth backup doesn't exist! " && exit 1 fi

echo -e "Restoring /etc/security/access.conf" 
cp -f $backup/access.conf /etc/security/access.conf
        if [ "$?" = "0" ]; then echo -e "Done!" || echo -e "Failed to restore /etc/security/access.conf backup doesn't exist! " && exit 1 fi
echo -e "All files have been restored. " 

echo -e "Check if $dir is empty..."
if [ "$( ls -A $dir )" ]; then
	echo -e "Changing user/group permissions on home directories....\n"
        for username in $( ls -l $dir | awk '{print $9}' ); do chown -R $username $dir/$username && chmod 700 $dir/$username
                        if [ "$?" = "0" ]; then echo -e "User permissions for $username are Done!" || echo -e "Failed to change user permissions for $username! $username doesn't exist."
                        fi
                groupname=`id -gn $username` && chgrp -R $groupname $dir/$username
                        if [ "$?" = "0" ]; then echo -e "Group permissions for $username are Done!" || echo -e "Failed to change group permissions for $username! $username doesn't exist."
                        fi
	done
else echo -e "$dir is empty!"
fi
echo -e "Restarting services"
newaliases
service sshd restart
chkconfig nscd off
service nscd stop
service sendmail stop
echo -e "LDAP changes have been reverted. All done! "
