#!/usr/bin/env bash
# shellcheck disable=SC2013,SC2016,SC2034,SC2035

old_version=$1
new_version=$2

for i in $(grep -Rn "$old_version" ~/BitBucket/TechOpsCICD/govcloud-jfrog-k8s-stack/* |awk -F: '{print $1}' |grep -Ev "binary|charts|terraform"); do 
    sed -i 's/$old_version/$new_version/g' "$i"
done
