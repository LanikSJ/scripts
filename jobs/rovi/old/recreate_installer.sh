#!/bin/bash
if [ -d "/var/www/store.ws.trygames.com/installer" ] ;then
echo "Folder exists"
else 
cp /var/www/store.ws.trygames.com/installer_orig  /var/www/store.ws.trygames.com/installer -r
chown -R www-data:www-data /var/www/store.ws.trygames.com/installer
echo "Install directory recreated"
fi
