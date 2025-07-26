#!/usr/bin/env bash
# This Script Will Check If PR Checks Complete Then Squash and Merge
# ./script.sh <pr number>

gh pr checks "$1" --watch -i 5
gh pr merge "$1" -s -d --auto
