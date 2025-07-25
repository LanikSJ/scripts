#!/bin/bash

groups="ce_bm           \
        cs_dev          \
        cpg             \
        mrr_eng         \
        mrr_dev         \
        projectq_dev    \
        rcs_dev         \
        widgetlogs      \
        wsp_perf        \
        wsp_poc         \
        wsp_sr          \
        wsp_sr_bnr"

for i in $groups
do
        if [ `grep $i /etc/security/access.conf > /dev/null 2>&1; echo $?` -eq 0 ]; then
                echo "Access exists"
        fi
done
