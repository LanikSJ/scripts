#!/usr/bin/env bash
# Removes TrendMicro

sudo /sbin/SystemStarter stop iCoreService
sudo killall TmLoginMgr
sudo killall UIMgmt
sudo killall MainUI
sudo /Library/Application\ Support/TrendMicro/TmccMac/TmLoginMgr.app/Contents/MacOS/TmLoginMgr –u
sudo rm –rf –R /System/Library/TrendMicro
sudo rm –rf –R /Library/StartupItems/iCoreService
sudo rm –rf –R /Applications/MainUI.app
sudo rm –rf –R /Library/Application Support/TrendMicro
sudo rm –rf –R /Library/Frameworks/TMAppCommon.framework
sudo rm –rf –R /Library/Frameworks/TMAppCore.framework
sudo rm –rf –R /Library/Frameworks/TMGUIUtil.framework
sudo rm –rf –R /Library/Frameworks/iCoreClient.framework
sudo rm –rf –R /Library/Preferences/TMCNTMgmt.plist
