#!/bin/bash
IFS=' ' read -ra array <<< "$INSTANCES"
echo "Array 1:" && echo "${array[0]}"
echo "Array 2:" && echo "${array[1]}"
echo "Array 3:" && echo "${array[2]}"
echo "Total: " && echo ${#array[@]}
