#!/usr/bin/env bash
# Script to Ignore .git folders in Dropbox !!VERY BROKEN!!

find ~/GitHub/ -iname .git -type d -exec xattr -w com.dropbox.ignored 1 {} \;
find ~/GitLab/ -iname .git -type d -exec xattr -w com.dropbox.ignored 1 {} \;
find ~/.vim/ -iname .git -type d -exec xattr -w com.dropbox.ignored 1 {} \;

xattr -w com.dropbox.ignored 1 ~/Pictures/Photos\ Library.photoslibrary
xattr -w com.dropbox.ignored 1 ~/Movies/iMovie\ Library.imovielibrary
xattr -w com.dropbox.ignored 1 ~/Movies/iMovie\ Theater.theater

