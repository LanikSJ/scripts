#!/bin/bash
if [ ! -d /var/www/store.ws.trygames.com/installer_orig ] ;
then
cp -rp /var/www/store.ws.trygames.com/installer /var/www/store.ws.trygames.com/installer_orig
else
echo "The backup exists"
fi
if [ -d /var/www/store.ws.trygames.com/installer ] ;
then
echo "The installer is still alive"
else
echo "The installer is missing, I will replace it!"
cp -rp /var/www/store.ws.trygames.com/installer_orig /var/www/store.ws.trygames.com/installer
echo "It seems that the installer has been deleted.  I have restored it. ;-)" | mail -s "`hostname` installer" noc-alerts@macrovision.com,dep-publish@macrovision.com
fi

