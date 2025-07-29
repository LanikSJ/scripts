#!/bin/bash
set -euo pipefail

LOCKFILE="/var/lock/sphinxlockfile"
SPHINX_USER="sphinx"
INDEXER="/var/lib/sphinx/bin/indexer"
CONFIG="/var/lib/sphinx/etc/sphinx.conf"

# Ensure lock file exists and is owned by sphinx
if [[ -e "$LOCKFILE" ]]; then
    /bin/chown "${SPHINX_USER}:${SPHINX_USER}" "$LOCKFILE"
else
    /bin/touch "$LOCKFILE"
    /bin/chown "${SPHINX_USER}:${SPHINX_USER}" "$LOCKFILE"
fi

# Function to pause with a prompt
pause() {
    read -r -p "$*" 1>&2
}

# Check if current user is sphinx (user id 5111)
if [[ "$(id -u)" != "5111" ]]; then
    cat >&2 <<-'EOF'
    *****                                              *****
    *****      This script must be run as sphinx!      *****
    *****      This script will sudo to sphinx now!    *****
    *****                                              *****
EOF

    pause "***** Press any key to continue or Ctrl+C to exit  *****"

    # Run indexer via sudo and flock as sphinx
    /usr/bin/sudo /bin/su - "${SPHINX_USER}" -c \
    "/usr/bin/flock -n -x '$LOCKFILE' -c \"$INDEXER --config $CONFIG --all --rotate\""

    exit 0
fi

# If already running as sphinx, run indexer directly
/usr/bin/flock -n -x "$LOCKFILE" -c "$INDEXER --config $CONFIG --all --rotate"
