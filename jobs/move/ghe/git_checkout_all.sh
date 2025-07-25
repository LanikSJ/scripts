#!/usr/bin/env bash

if [[ -d .git ]]; then
    for i in $(git checkout -- |grep -v branch |awk '{print $2}'); do git checkout -- $i; done
fi
