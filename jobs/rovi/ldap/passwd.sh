#!/bin/sh
# This script extracts and numerically sorts user IDs (UIDs) from the system's password database,
# then displays them in a paginated view.

getent passwd | cut -d: -f3 | sort -n | less
