#!/bin/bash

# create directories
mkdir /root/src
mkdir /local

# place config files in required paths
wget -P /root/src  http://ks1.sjc.trymedia.com/post/dli/conf/iptables
cp -f /root/src/iptables /etc/sysconfig/

# amhttpd
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/logs.conf
cp -f /root/src/logs.conf /etc/httpd/conf.d/
wget -P /root/src http://ks1.sjc.trymedia.com/post/src/trymedia/amhttpd_2.6.tgz
tar -C /root/src -xzvf /root/src/amhttpd_2.6.tgz
cp -rf /root/src/amhttpd_2.6/* /
/bin/bash /root/src/amhttpd_2.6/install.sh
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/amhttpd
cp -f /root/src/amhttpd /etc/logrotate.d/
chmod -R 777 /var/log/amhttpd
chown -R root.root /var/log/amhttpd
chkconfig --add amhttpd

# httpd.conf
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/httpd.conf
mv -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
cp -f /root/src/httpd.conf /etc/httpd/conf/

# set up catalog sync
useradd -s /bin/bash -c "uploadr, APP" -m -k /etc/skel -d /home/uploadr uploadr
wget -P /root/src http://ks1.sjc.trymedia.com/post/src/trymedia/rsync.tgz
tar -C /root/src -xzvf /root/src/rsync.tgz
cp -rf /root/src/rsync /home/uploadr
chown -R uploadr.uploadr /home/uploadr/
mkdir /catalog
chown -R uploadr.uploadr /catalog
chmod -R 777 /catalog

# set up rrd
wget -P /root/src http://ks1.sjc.trymedia.com/post/src/trymedia/rrd.tgz
tar -C /root/src -xzvf /root/src/rrd.tgz
cp -rf /root/src/rrd/* /

# schedule rrd and rsync
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/crontab
cp -f /root/src/crontab /etc

# 3ware-utils and client tools
wget -P /root/src http://ks1.sjc.trymedia.com/post/src/trymedia/3ware-utils.tgz
tar -C /root/src -xzvf /root/src/3ware-utils.tgz
cp -rf /root/src/3ware-utils/* /
chkconfig --add 3dm2
mkdir /local/3ware_twi
wget -P /root/src http://ks1.sjc.trymedia.com/post/src/trymedia/tw_cli-linux-x86-9.3.0.7.tgz
tar -C /local/3ware_twi -xzvf /root/src/tw_cli-linux-x86-9.3.0.7.tgz

# copy fstab into place
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/fstab
cp -f /root/src/fstab /etc

#prepare for the future
sed 's/^/#/' /etc/sysconfig/network-scripts/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth0:1
mkdir /root/.ssh
wget -P /root/src http://ks1.sjc.trymedia.com/post/dli/conf/authorized_keys
cp -f /root/src/authorized_keys /root/.ssh

