#!/bin/bash
set -e

INSTALL_DIR="/var/www/store.ws.trygames.com/installer"
ORIG_DIR="/var/www/store.ws.trygames.com/installer_orig"
WEB_USER="www-data"
WEB_GROUP="www-data"

if [ -d "$INSTALL_DIR" ]; then
    echo "Info: Installer directory '$INSTALL_DIR' already exists. No action taken."
else 
    echo "Info: Installer directory '$INSTALL_DIR' not found. Recreating..."
    
    # Copy the original installer directory
    if ! cp -r "$ORIG_DIR" "$INSTALL_DIR"; then
        echo "Error: Failed to copy '$ORIG_DIR' to '$INSTALL_DIR'." >&2
        exit 1
    fi
    echo "Info: Copied '$ORIG_DIR' to '$INSTALL_DIR'."

    # Change ownership
    if ! chown -R "$WEB_USER":"$WEB_GROUP" "$INSTALL_DIR"; then
        echo "Error: Failed to change ownership of '$INSTALL_DIR' to '$WEB_USER':'$WEB_GROUP'." >&2
        exit 1
    fi
    echo "Info: Changed ownership of '$INSTALL_DIR' to '$WEB_USER':'$WEB_GROUP'."

    echo "Success: Install directory '$INSTALL_DIR' recreated and permissions set."
fi
