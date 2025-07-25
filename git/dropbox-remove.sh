#!/usr/bin/env bash
# Script to undo the Dropbox Ignore !!VERY BROKEN!!

find . -type d -xattrname com.dropbox.ignored -exec xattr -d com.dropbox.ignored {} \;
find . -type f -xattrname com.dropbox.ignored -exec xattr -d com.dropbox.ignored {} \;
