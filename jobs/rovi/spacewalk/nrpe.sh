#!/bin/bash
set -euo pipefail

# Check if NRPE package is installed
if rpm -q nrpe > /dev/null 2>&1; then
    # Fetch configuration and plugin script
    rhncfg-client get /etc/nagios/nrpe.cfg /usr/lib/nagios/plugins/check_mem_proc.sh

    # Set executable and ownership permissions
    chmod +x /usr/lib/nagios/plugins/check_mem_proc.sh
    chown -R nagios:nagios /usr/lib/nagios

    # Restart NRPE service
    service nrpe restart
    exit 0
else
    echo "Nagios not installed!"
    exit 1
fi
