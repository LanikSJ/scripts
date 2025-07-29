#!/bin/bash
set -euo pipefail

# Check if 'nrpe' process is running
if pgrep -x nrpe > /dev/null 2>&1; then
    rhncfg-client get /etc/nagios/nrpe.cfg
    service nrpe restart

# If hostname is exactly 'sjc1nag01', exit with status 5
elif [[ $(hostname -s) == "sjc1nag01" ]]; then
    exit 5

# Otherwise, remove nagios configuration and binaries
else
    mv -f /etc/nagios/nrpe.cfg /tmp/
    mv -f /usr/lib/nagios/* /tmp/
    rm -rf /etc/nagios /usr/lib/nagios
    echo "Nagios configuration removed"
fi
