#!/usr/bin/env bash

i=1
while [ "$i" -ne 0 ]
do
    pid=$(ps aux | pgrep "UserEventAgent") || true
    if [[ -z $pid ]]; then
      sleep 5
    else
      kill -9 "$pid" && sleep 5
    fi
done
