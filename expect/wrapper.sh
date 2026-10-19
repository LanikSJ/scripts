#!/usr/bin/env bash
# Wrapper for the expect scripts
# Usage: ./wrapper.sh <host-list-file> <command>

while IFS= read -r i; do
    ~/bin/expect/ssh_co.sh "$i" "$2"
done < "$1"
