#!/usr/bin/env bash
# Removes TrendMicro

set -e

echo "Stopping TrendMicro services..."
sudo /sbin/SystemStarter stop iCoreService || echo "Warning: iCoreService might not be running or SystemStarter failed."
sudo killall TmLoginMgr || echo "Warning: TmLoginMgr not found or failed to kill."
sudo killall UIMgmt || echo "Warning: UIMgmt not found or failed to kill."
sudo killall MainUI || echo "Warning: MainUI not found or failed to kill."

echo "Attempting to uninstall TrendMicro components..."
sudo "/Library/Application Support/TrendMicro/TmccMac/TmLoginMgr.app/Contents/MacOS/TmLoginMgr" -u || echo "Warning: Uninstallation command failed."

echo "Removing TrendMicro files and directories..."
# Consolidate rm commands for better readability and efficiency
declare -a paths_to_remove=(
    "/System/Library/TrendMicro"
    "/Library/StartupItems/iCoreService"
    "/Applications/MainUI.app"
    "/Library/Application Support/TrendMicro"
    "/Library/Frameworks/TMAppCommon.framework"
    "/Library/Frameworks/TMAppCore.framework"
    "/Library/Frameworks/TMGUIUtil.framework"
    "/Library/Frameworks/iCoreClient.framework"
    "/Library/Preferences/TMCNTMgmt.plist"
)

for path in "${paths_to_remove[@]}"; do
    if [ -e "$path" ]; then
        echo "Removing: $path"
        sudo rm -rf "$path" || echo "Error: Failed to remove $path"
    else
        echo "Skipping: $path (not found)"
    fi
done

echo "TrendMicro removal script completed."
