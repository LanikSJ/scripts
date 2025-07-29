#!/bin/bash

# Define groups as an array for safety
groups=(
  "ce_bm"
  "cs_dev"
  "cpg"
  "mrr_eng"
  "mrr_dev"
  "projectq_dev"
  "rcs_dev"
  "widgetlogs"
  "wsp_perf"
  "wsp_poc"
  "wsp_sr"
  "wsp_sr_bnr"
)

access_file="/etc/security/access.conf"

for group in "${groups[@]}"; do
    if grep -q -- "$group" "$access_file"; then
        echo "Access exists for $group"
    else
        echo "No access found for $group"
    fi
done
