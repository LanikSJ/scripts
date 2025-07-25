#!/bin/sh
#
# Ilan Erenstein
# Version:  1.08
#
# Changelog:
# - 02/26/2010 -- Added backup of resolv.conf
# - 03/09/2010 -- Changed dir variable and changed directory perms to 750 instead of 700
# - 05/25/2010 -- Added Yum repos setup for rhelupd1 and 2 and sendmail setup for screlay.corporate.local
# - 06/01/2010 -- Added new backup folder in /root/backup if the backup already exists make a new one and append date+time to the file name
# - 06/22/2010 -- Added new menus for Update Servers, CORP vs ARMUS and added new CORP configs to the script
# - 10/04/2010 -- Modified the script to remove the sendmail queue before installing and compiling it
# - 10/13/2010 -- Make the appropriate changes to submit.mc to prevent relay through localhost
# - 10/18/2010 -- Added submit.mc and sendmail.mc to the template and script 
# - 12/28/2010 -- Added removal of clientmqueue in sendmail
# - 01/28/2011 -- Chkconfig sendmail to on
#
# This script will setup LDAP authentication for Rovi ARMUS or CORPORATE domain
#

# Variables
sjc1="rhelupd1.sjc.macrovision.com"
sjc2="rhelupd2.sjc.macrovision.com"
corp1="rhelupd1.corporate.local"
corp2="rhelupd2.corporate.local"
build1="rhelbuild01.corporate.local"
build2="rhelbuild02.corporate.local"
#date=$(date "+%Y%m%d_%H%M")
backup="/root/backup"
dir="/home"

# Add a pause
        function pause(){
        read -p "$*"
        }

# Check if script is run as root
if [ `id -u` != 0 ]; then echo -e "Sorry, You must be root to run this script." && exit 1 
fi

# Define Update Servers
cat << MENU

 This script is used to install LDAP configuration into RHEL5. 

 Make sure you have connectivity to one of the Update Servers. Otherwise this script will not work. 
 Check your /etc/resolv.conf and if you're using 192.168.0.42/43/44 choose option 1. If option 1 doesn't work try option 2. 

 Which update servers should we use for the update? :

       1.  rhelupd1/2 on sjc.macrovision.com (Equinix)
       2.  rhelupd1/2 on corporate.local (Equinix)
       3.  rhelbuild01/02 -- Build Servers (Corporate)

MENU

printf "Enter choice [1-3, press any key to exit]: "

read channelchoice

case "$channelchoice"
in
  1)
	if ping -c 1 "$sjc1" > /dev/null; then upd_server="$sjc1" && echo && echo -e "Using $upd_server server for this update."
	elif ping -c 1 "$sjc2" > /dev/null; then upd_server="$sjc2" && echo && echo -e "Using $upd_server server for this update."
		else echo && echo "Sorry, it appears this machines has no icmp connectivity to Equinix Update Servers."  && exit 1
	fi
	;;
  2)
	if ping -c 1 "$corp1" > /dev/null; then upd_server="$corp1" && echo && echo -e "Using $upd_server server for this update."
	elif ping -c 1 "$corp2" > /dev/null; then upd_server="$corp2" && echo && echo -e "Using $upd_server server for this update."
		else echo && echo "Sorry, it appears this machines has no icmp connectivity to Corporate Update Servers." && exit 1
	fi
	;;
  3)
	if ping -c 1 "$build1" > /dev/null; then upd_server="$build1" && echo && echo -e "Using $upd_server server for this update."
	elif ping -c 1 "$build2" > /dev/null; then upd_server="$build2" && echo && echo -e "Using $upd_server server for this update."
		else echo && echo "Sorry, it appears this machines has no icmp connectivity to Corporate Build Servers." && exit 1
	fi
	;;

  *)
	echo && echo This script will now exit!
	exit 0
	;;

esac

cat << MENU

 ARMUS sjc1extdc1/2
 CORPOATE scl1ad1/2

 Which LDAP configuration would you like? :

	1. ARMUS
	2. CORPORATE

MENU

printf "Enter choice [1-2, press any key to exit]: "

read channelchoice

case "$channelchoice"
in
  1)
	# Download LDAP templates
	echo && echo -e "Downloading LDAP ARMUS configuration files!"
	wget -q -O /tmp/ldap_conf_armus.tar.gz http://$upd_server/redhat/misc/5Server/templates/ldap/ldap_conf_armus.tar.gz
	if [ "$?" = "0" ]; then	echo -e "Done!" 
		else echo && echo -e "LDAP ARMUS configuration didn't download! " && exit 1 
	fi

	# Extract LDAP configs
	echo && echo -e "Extracting LDAP configuration to /tmp " 
	cd /tmp && tar xvzf /tmp/ldap_conf_armus.tar.gz
	if [ "$?" = "0" ]; then echo -e "Done! " && echo 
		else echo && echo -e "Failed to extract LDAP configuration files to /tmp! " && exit 1 
	fi

	# Setting up Yum Repos
	echo && echo -e "Setting up Yum Repos"
	sed -i 's/rhelbuild01.macrovision.com/rhelupd1.sjc.macrovision.com/g' /etc/yum.repos.d/*.repo 
	sed -i 's/rhelbuild02.macrovision.com/rhelupd2.sjc.macrovision.com/g' /etc/yum.repos.d/*.repo 
	echo -e "Done!"

	# Setting up sendmail
	echo && echo -e "Setting up sendmail" && yum clean all && yum -y install sendmail-cf 
	if [ -f /etc/mail.sendmail.cf.rpmnew ]; then rm -f /etc/mail/sendmail.cf.rpmnew 
		else echo -e "Done! " && echo
	fi
	echo -e "Setting up sendmail.cf" && service sendmail stop && echo -e "Removing the mail queue." &&  rm -rf /var/spool/mqueue/* && rm -rf /var/spool/clientmqueue/*
	echo -e "Done! " && echo
	;;
  2)
	# Download LDAP templates
	echo && echo -e "Downloading LDAP CORPORATE configuration files" 
	wget -q -O /tmp/ldap_conf_corp.tar.gz http://$upd_server/redhat/misc/5Server/templates/ldap/ldap_conf_corp.tar.gz
	if [ "$?" = "0" ]; then	echo -e "Done!" 
		else echo && echo -e "LDAP CORPORATE configuration didn't download! " && exit 1
	fi

	# Extract LDAP configs
	echo && echo -e "Extracting LDAP configuration to /tmp " 
	cd /tmp && tar xvzf /tmp/ldap_conf_corp.tar.gz
	if [ "$?" = "0" ]; then echo -e "Done! " && echo 
		else echo && echo -e "Failed to extract LDAP configuration files to /tmp! " && exit 1 
	fi

	# Setting up sendmail
	echo && echo -e "Installing sendmail.cf" && yum clean all && yum -y install sendmail-cf 
	if [ -f /etc/mail.sendmail.cf.rpmnew ]; then rm -f /etc/mail/sendmail.cf.rpmnew 
		else echo -e "Done! " && echo
	fi
	echo -e "Setting up sendmail.cf" && service sendmail stop && echo -e "Removing the mail queue." &&  rm -rf /var/spool/mqueue/* && rm -rf /var/spool/clientmqueue/*
	echo -e "Done! " && echo
	;;
  *)
	echo && echo This script will now exit!
	exit 0
	;;

esac
	
echo -e "Creating backup directory $backup" && mkdir -p $backup && echo

# /etc/issue
file="issue"
folder="/etc"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/ssh/sshd_config
file="sshd_config"
folder="/etc/ssh"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/mail/sendmail.cf
file="sendmail.cf"
folder="/etc/mail"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/mail/sendmail.mc
file="sendmail.mc"
folder="/etc/mail"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/mail/submit.cf
file="submit.cf"
folder="/etc/mail"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/mail/submit.mc
file="submit.mc"
folder="/etc/mail"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/mail/ldap
file="ldap"
folder="/etc/mail"

if [ -f  $folder/$file ]; then echo -e "$folder/$file already exists!"
else echo -e "Adding new $folder/$file" && mv -f /tmp/$file $folder/$file 
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/aliases
file="aliases"
folder="/etc"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# cacerts
#file="f114b579.0"
#file="bdf84889.0"
folder="/etc/openldap/cacerts"

#if [ -f  $folder/$file ]; then echo -e "$folder/$file already exists!"
#else echo -e "Adding new $folder/$file" && mv -f /tmp/$file $folder/$file
echo -e "Adding new LDAP cert" && mv -f /tmp/*9.0 $folder/
	if [ "$?" = "0" ]; then echo -e "Done!" 
		#else echo -e "Failed to add new $folder/$file! " && exit 1 
		else echo -e "Failed to add new LDAP cert! " && exit 1 
	fi
#fi

# /etc/openldap/ldap.conf
file="ldap.conf"
folder="/etc/openldap"

if [ -f $backup/open$file ]; then echo -e "$backup/open$file exists!" && echo -e "Removing $folder/$file!" && rm -rf $folder/$file 
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to remove $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup/open$file
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Removing $folder/$file!" && rm -rf $folder/$file
        if [ "$?" = "0" ]; then echo -e "Done!"
                else echo -e "Failed to remove $folder/$file!" && exit 1
        fi
fi

# /etc/ldap.conf
file="ldap.conf"
folder="/etc"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

#openldap="/etc/openldap"
#echo -e "Creating a symbolic link for $folder/$file" && ln -s $folder/$file $openldap/$file
echo -e "Creating a symbolic link for $folder/$file" && ln -s /etc/ldap.conf /etc/openldap/ldap.conf 
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to symbolic link for /etc/openldap/ldap.conf to /etc/ldap.conf! " && exit 1 
	fi

# /etc/nsswitch.conf
file="nsswitch.conf"
folder="/etc"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/pam.d/system-auth
file="system-auth-ac"
folder="/etc/pam.d"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/security/access.conf
file="access.conf"
folder="/etc/security"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

# /etc/resolv.conf
file="resolv.conf"
folder="/etc"

if [ -f $backup/$file ]; then echo -e "$backup/$file exists!" && echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to move $folder/$file!" && exit 1 
	fi
else echo -e "Creating a backup of $folder/$file!" && mv -f $folder/$file $backup 
	if [ "$?" = "0" ]; then echo -e "Done!"
		else echo -e "Failed to make backup of $folder/$file!" && exit 1
	fi
	echo -e "Adding new $folder/$file!" && mv -f /tmp/$file $folder/$file
	if [ "$?" = "0" ]; then echo -e "Done!" 
		else echo -e "Failed to add new $folder/$file!" && exit 1 
	fi
fi

echo -e "Changing permissions on files just moved.... "
chmod 444 /etc/issue /etc/mail/sendmail.cf /etc/mail/submit.cf && chmod 600 /etc/ssh/sshd_config && chmod 400 /etc/mail/ldap && chmod 644 /etc/openldap/cacerts/* /etc/ldap.conf /etc/nsswitch.conf /etc/pam.d/system-auth /etc/security/access.conf
	if [ "$?" = "0" ]; then echo -e "Permissions done!\n" 
		else echo -e "Failed to change permissions on files just moved! " && exit 1 
	fi

# Restarting services
chkconfig sendmail on && chkconfig nscd on && rm -f /var/db/nscd/* && service nscd restart && service sshd restart && newaliases && service sendmail restart && echo

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
echo && echo -e "All done! "
echo && echo -e "LDAP Installation has been completed."
echo -e "DON'T LOGOFF YET! Test your login in another connection to this server."
echo -e "You should now be able to login to this server with your ARMUS credentials."
