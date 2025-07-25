#!/bin/bash
hponcfg -w /tmp/ilo_cfg.xml
sed -e '41,52d' /tmp/ilo_cfg.xml > /tmp/ilo_cfg_fixed.xml
sed -i 's/10.110.208/10.110.60/g' /tmp/ilo_cfg_fixed.xml
hponcfg -f /tmp/ilo_cfg_fixed.xml -l /tmp/ilo.log
ping -c10 `cat /tmp/ilo_cfg_fixed.xml |grep IP_ADDRESS |grep -v GATEWAY |awk '{print $4}' |sed 's/"//g' |sed 's/\/>//g'`