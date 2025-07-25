#!/usr/bin/env bash
# Check Who Modified the File in Git Repo
# shellcheck disable=SC1083

git blame "$1" | awk {'printf ("%3s\t%s\n", $2, $3)'} | cut -c2- | sort | uniq -c | sort -nr
