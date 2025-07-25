#!/usr/bin/env bash
# usage: watch.sh <your_command> <sleep_duration>
# shellcheck disable=SC2005

while :; 
  do 
  clear; 
  echo "$(date)"
  $1; 
  sleep "$2";
done
