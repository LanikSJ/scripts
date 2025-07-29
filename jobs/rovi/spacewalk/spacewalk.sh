#!/bin/bash
set -euo pipefail

# Ilan Erenstein
# Version:  1.0
#
# Changelog:
# - 05/24/2012 -- Initial version of the script.
# - 06/12/2012 -- Now script uses hostnames.
#
# This script will setup install Spacewalk for the first time.

# Determine server based on hostname (lowercased)
hostname_lower=$(hostname | tr '[:upper:]' '[:lower:]')

if [[ "$hostname_lower" == *tul* ]]; then
    SERVER="tul1itpswpxy01"
elif [[ "$hostname_lower" == *lux* ]]; then
    SERVER="lux2itpswpxy01"
elif [[ "$hostname_lower" =~ sjc|amgsj ]]; then
    SERVER="sjc1itpswpxy01"
else
    SERVER="tul1itpswpxy01"
fi

# Remove existing 5Server repo files if any
rm -f /etc/yum.repos.d/5Server*

# Remove existing systemid file if any
rm -f /etc/sysconfig/rhn/systemid

# Download the Spacewalk deployment script
wget -q -O /tmp/spacewalk-deploy.sh "http://$SERVER/pub/spacewalk-deploy.sh"
chmod +x /tmp/spacewalk-deploy.sh

# Run the deployment script
/tmp/spacewalk-deploy.sh

# Update Spacewalk related packages
yum -y update rhncfg* rhnsd* osad

# Remove logwatch package if installed
yum -y remove logwatch

# Restart services
service rhnsd restart
service osad restart
