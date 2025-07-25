#!/usr/bin/env bash
# Get All Branches in Given Repo

for remote in $(git branch -r | grep -v /HEAD | grep -v master); do git checkout --track "$remote" ; done
