#!/usr/bin/env bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "Not running as root or using sudo"
  exit
fi

launchctl unload /Library/LaunchDaemons/com.tanium.taniumclient.plist
mv -f /Library/LaunchDaemons/com.tanium.taniumclient.plist /Library/Tanium/
mv -f /Library/Tanium/TaniumClient/TaniumClient /Library/Tanium/TaniumClient/TaniumClient.migrated
chmod -x /Library/Tanium/TaniumClient/TaniumClient.migrated
mv -f /var/db/receipts/com.tanium.taniumclient.TaniumClient.pkg.bom /Library/Tanium/
mv -f /var/db/receipts/com.tanium.taniumclient.TaniumClient.pkg.plist /Library/Tanium/
