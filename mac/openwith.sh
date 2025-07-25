#!/usr/bin/env bash
# This script will cleanup the shortcuts for "Open With" feature in macOS

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -all local, system, user; killall Dock;

echo && echo "Bob's your Uncle! "
