#!/usr/bin/env bash

echo && echo "Removing Cocoapods Cache and DerivedData"
rm -rf ~/Library/Caches/CocoaPods; rm -rf ~/Library/Developer/Xcode/DerivedData/

echo && echo "Remove Archives Older Then 90 Days"
find ~/Library/Developer/Xcode/Archives -type d -ctime +90 -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
