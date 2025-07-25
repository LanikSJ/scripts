#!/bin/bash
# Spacewalk setup script for ESX
# 2012-04-11 - Brian Rahn, initial version

# Determine proxy and registration key
# Take different paths based on which name server was given
# ========================================

HOST=`hostname --short`

rpm -Uvh http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/yum-3.2.8-9.el5.noarch.rpm \
  http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/yum-metadata-parser-1.1.2-2.el5.x86_64.rpm \
  http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/python-iniparse-0.2.3-4.el5.noarch.rpm
rpm -Uvh --nodeps http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/rhpl-0.194.1-1.x86_64.rpm

cat > /etc/yum.repos.d/5Server-Base-2.repo << End-of-File
[5Server-Base-2]
name=Red Hat Enterprise Linux $releasever - $basearch - Base - U5
baseurl=http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server
failovermethod=roundrobin
enabled=1
exclude=kernel*
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
End-of-File


# By default, use the Tulsa ARMUS config.  At least we can log on to fix it.
PROXY="tul1itpswpxy01.corporate.local"
SW_KEY5="esx4-64-tul-corp"

case "$HOST" in
  tul1virt*)
    # Tulsa
    PROXY="tul1itpswpxy01.corporate.local"
    SW_KEY5="1-esx4-64-tul-corp"
    ;;
  sjc1virt*)
    # BAIS
    PROXY="sjc1itpswpxy01.corporate.local"
    SW_KEY5="1-esx4-64-sjc-corp"
    ;;
  ann1virt*)
    PROXY="ann1itpswpxy01.corporate.local"
    SW_KEY5="1-esx4-64-ann-corp"
    ;;
  lux2virt*)
    PROXY="lux2itpswpxy01.corporate.local"
    SW_KEY5="1-esx4-64-lux-corp"
    ;;
  *)
    echo "This script only works for ESX hosts"
    exit
    ;;
esac

echo "Proxy Server: $PROXY"
echo "RHEL5 Key:    $SW_KEY5"

# Begin Spacewalk setup process
# ========================================

echo ''
echo 'RHEL6 complains if you import keys you already have.  That is fine.'
echo '========================================'

/bin/rpm --force -i http://$PROXY/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-redhat-release
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-EPEL
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-EPEL-6
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-spacewalk
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-spacewalk-2010
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-spacewalk-2012
/bin/rpm --import http://$PROXY/pub/SPACEWALK-CLIENT-TOOLS-RPM-GPG-KEY
/bin/rpm --import http://$PROXY/pub/RPM-GPG-KEY-ROVI-ITLINUX

yum -y install yum-rhn-plugin rhn-setup wget rsync

if ! /sbin/service messagebus status
then
   /sbin/service messagebus start

   if ! /sbin/service messagebus status
   then
      echo "Messagebus won't start"
      exit 1
   fi
fi

if ! /sbin/service haldaemon status
then
   /sbin/service haldaemon start
   if ! /sbin/service haldaemon status
   then
      echo "Haldaemon won't start"
#      exit 2
   fi
fi


perl -pi -e 's|/usr/share/rhn/RHNS-CA-CERT|/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT|' /etc/sysconfig/rhn/up2date

echo ''

if [ -e /etc/sysconfig/rhn/systemid ]
then
  if ! grep -q "$HOST" /etc/sysconfig/rhn/systemid
  then
    echo "Registration appears invalid!"
    echo "Clearing existing data..."
    echo ''
    rm -f /etc/sysconfig/rhn/systemid
    rm -f /etc/sysconfig/rhn/osad-auth.conf
  else
    echo "This system is already registered!"
    echo "To re-register, you must remove /etc/sysconfig/rhn/systemid"
    echo ''
  fi

fi

# Take different paths based RHEL version
# ========================================

if grep -q 'Tikanga' /etc/redhat-release
then
  # RHEL version 5
  if [ ! -e /etc/sysconfig/rhn/systemid ]
  then
    echo "Registering RHEL5 (Tikanga)"
    /usr/sbin/rhnreg_ks --force --serverUrl=http://$PROXY/XMLRPC --activationkey=$SW_KEY5
  fi

  /usr/bin/perl -pi -e 's/enabled.*=.*$/enabled = 1/' /etc/yum/pluginconf.d/rhnplugin.conf
  /usr/bin/yum -y install 'rhncfg*' osad

  /usr/bin/rhn-actions-control --enable-all
  /usr/bin/rhncfg-client get /etc/sysconfig/rhn/rhncfg-client.conf /usr/share/rhn/osad/jabber_lib.py
  /sbin/chkconfig osad on
  /sbin/chkconfig rhnsd on
  /sbin/service rhnsd restart
  /sbin/service osad restart
fi

