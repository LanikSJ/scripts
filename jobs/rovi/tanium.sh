#!/usr/bin/env bash

set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "Error: This script must be run as root or with sudo." >&2
  exit 1
fi

LAUNCHD_PLIST="/Library/LaunchDaemons/com.tanium.taniumclient.plist"
LIBRARY_TANIUM="/Library/Tanium"
TANIUMCLIENT_DIR="${LIBRARY_TANIUM}/TaniumClient"
MIGRATED_BIN="${TANIUMCLIENT_DIR}/TaniumClient.migrated"
RECEIPTS_DIR="/var/db/receipts"
RECEIPT_BOM="${RECEIPTS_DIR}/com.tanium.taniumclient.TaniumClient.pkg.bom"
RECEIPT_PLIST="${RECEIPTS_DIR}/com.tanium.taniumclient.TaniumClient.pkg.plist"

# Unload the plist if it exists before moving
if [[ -f "$LAUNCHD_PLIST" ]]; then
  echo "Unloading $LAUNCHD_PLIST..."
  if ! launchctl unload "$LAUNCHD_PLIST"; then
    echo "Warning: Failed to unload $LAUNCHD_PLIST" >&2
  fi

  echo "Moving $LAUNCHD_PLIST to $LIBRARY_TANIUM..."
  mv -f "$LAUNCHD_PLIST" "$LIBRARY_TANIUM/"
else
  echo "Warning: $LAUNCHD_PLIST does not exist, skipping unload and move."
fi

# Rename TaniumClient executable if it exists
if [[ -f "${TANIUMCLIENT_DIR}/TaniumClient" ]]; then
  echo "Renaming TaniumClient binary to TaniumClient.migrated and removing execute permissions..."
  mv -f "${TANIUMCLIENT_DIR}/TaniumClient" "$MIGRATED_BIN"
  chmod -x "$MIGRATED_BIN"
else
  echo "Warning: TaniumClient binary not found at ${TANIUMCLIENT_DIR}/TaniumClient"
fi

# Move receipt files if they exist
if [[ -f "$RECEIPT_BOM" ]]; then
  echo "Moving $RECEIPT_BOM to $LIBRARY_TANIUM..."
  mv -f "$RECEIPT_BOM" "$LIBRARY_TANIUM/"
else
  echo "Warning: Receipt BOM file $RECEIPT_BOM not found."
fi

if [[ -f "$RECEIPT_PLIST" ]]; then
  echo "Moving $RECEIPT_PLIST to $LIBRARY_TANIUM..."
  mv -f "$RECEIPT_PLIST" "$LIBRARY_TANIUM/"
else
  echo "Warning: Receipt plist file $RECEIPT_PLIST not found."
fi

echo "Script completed."
