#!/bin/sh
#
# Ilan Erenstein 10/07/2010
# Version:  1.01
#
# This script will setup SNMPD for cacti.
#

# Variables
sjc1="rhelupd1.sjc.macrovision.com"
sjc2="rhelupd2.sjc.macrovision.com"
corp1="rhelupd1.corporate.local"
corp2="rhelupd2.corporate.local"
build1="rhelbuild01.corporate.local"
build2="rhelbuild02.corporate.local"

# Check if script is run as root
if [ `id -u` != 0 ]; then echo -e "Sorry, You must be root to run this script." && exit 1
fi

# Define Update Servers
cat << MENU

 This script is used to install SNMPD configuration into RHEL5.

 Make sure you have connectivity to one of the Update Servers. Otherwise this script will not work.
 Check your /etc/resolv.conf and if you're using 192.168.0.42/43/44 choose option 1. If option 1 doesn't work try option 2.

 Which update servers should we use for the update? :

       1.  rhelupd1/2 on sjc.macrovision.com (Equinix)
       2.  rhelupd1/2 on corporate.local (Equinix)
       3.  rhelbuild01/02 -- Build Servers (Corporate)

MENU

printf "Enter choice [1-3, press any key to exit]: "

read channelchoice

case "$channelchoice"
in
  1)
        if ping -c 1 "$sjc1" > /dev/null; then upd_server="$sjc1" && echo && echo -e "Using $upd_server server for this update."
        elif ping -c 1 "$sjc2" > /dev/null; then upd_server="$sjc2" && echo && echo -e "Using $upd_server server for this update."
                else echo && echo "Sorry, it appears this machines has no icmp connectivity to Equinix Update Servers."  && exit 1
        fi
        ;;
  2)
        if ping -c 1 "$corp1" > /dev/null; then upd_server="$corp1" && echo && echo -e "Using $upd_server server for this update."
        elif ping -c 1 "$corp2" > /dev/null; then upd_server="$corp2" && echo && echo -e "Using $upd_server server for this update."
                else echo && echo "Sorry, it appears this machines has no icmp connectivity to Corporate Update Servers." && exit 1
        fi
        ;;
  3)
        if ping -c 1 "$build1" > /dev/null; then upd_server="$build1" && echo && echo -e "Using $upd_server server for this update."
        elif ping -c 1 "$build2" > /dev/null; then upd_server="$build2" && echo && echo -e "Using $upd_server server for this update."
                else echo && echo "Sorry, it appears this machines has no icmp connectivity to Corporate Build Servers." && exit 1
        fi
        ;;

  *)
        echo && echo This script will now exit!
        exit 0
        ;;

esac

echo "Installing SNMPD!"
yum install -y net-snmp.x86_64 net-snmp-libs.x86_64 net-snmp-utils.x86_64 

echo "Download Cacti Configs...."
wget -O /tmp/cacti.tar.gz http://$upd_server/redhat/misc/5Server/templates/snmpd/cacti.tar.gz
if [ "$?" = "0" ]; then echo "Done!"
	else echo "Cacti configuration didn't download! " && exit 1
fi

echo "Extracting Cacti Configs...."
cd /tmp && tar xzvvf cacti.tar.gz
if [ "$?" = "0" ]; then echo "Done!"
	else echo "Cacti configuration didn't extract! " && exit 1
fi

echo "Adding SNMPD Configs...."
mv -f /tmp/snmpd.conf /etc/snmp/snmpd.conf
mv -f /tmp/snmpd.options /etc/sysconfig/snmpd.options 

echo "Installing SNMP Disk I/O...."
install -m 0755 -o root -g root -p -v /tmp/snmpdiskio /usr/local/bin/ && rm -f /tmp/snmpdiskio 

echo "Starting SMPD...."
chkconfig snmpd on && service snmpd start

cd - && echo "Done!"
