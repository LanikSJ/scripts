#!/usr/bin/env bash

# List of directories to process
read -r -d '' DIRS << EOD
AuthMan
Bacon
Butter
DashKit
DashKitMapSupport
Jubilee
PhantomSDK
Poutine
SCPAuthSDK
Sausage
ShortRibs
Sirloin
Spacebridge
SplunkAnalytics
SplunkCloudAuth
SplunkNotificationService
VictorOpsLib
EOD

# Iterate over directories
while IFS= read -r d; do
  # Check if directory exists
  if [[ ! -d "$d" ]]; then
    echo "Warning: Directory '$d' does not exist, skipping."
    continue
  fi

  # Use find with -print0 and xargs -0 to handle special characters in filenames
  # Exclude '.gitkeep' files
  find "$d" -type f ! -name '.gitkeep' -print0 | while IFS= read -r -d '' file; do
    # Lock the file with git lfs
    git lfs lock "$file" || echo "Failed to lock $file"
  done

done <<< "$DIRS"
