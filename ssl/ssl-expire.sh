#!/usr/bin/env bash
# Extract SSL certificate expiration dates.
# Usage ssl-expire.sh host port

echo | openssl s_client -connect "$1":"$2" 2>/dev/null | openssl x509 -noout -dates
