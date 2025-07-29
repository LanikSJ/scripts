#!/bin/bash
set -euo pipefail

# Spacewalk setup script for ESX
# 2012-04-11 - Brian Rahn, improved version

HOST=$(hostname --short)

# Upgrade RPM packages needed for yum on RHEL5
rpm -Uvh \
  "http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/yum-3.2.8-9.el5.noarch.rpm" \
  "http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/yum-metadata-parser-1.1.2-2.el5.x86_64.rpm" \
  "http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/python-iniparse-0.2.3-4.el5.noarch.rpm"

rpm -Uvh --nodeps "http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server/rhpl-0.194.1-1.x86_64.rpm"

# Create YUM repo file for 5Server-Base-2
cat > /etc/yum.repos.d/5Server-Base-2.repo <<EOF
[5Server-Base-2]
name=Red Hat Enterprise Linux \$releasever - \$basearch - Base - U5
baseurl=http://tul1itux5.corporate.local/redhat/os/5Server/x86_64/2/Server
failovermethod=roundrobin
enabled=1
exclude=kernel*
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

# Default proxy and registration key for Tulsa ARMUS config
PROXY="tul1itpswpxy01.corporate.local"
SW_KEY5="esx4-64-tul-corp"

# Adjust proxy and key based on host prefix
case "$HOST" in
  tul1virt*)
    PROXY="tul1itpswpxy01.corporate.local"
    SW_KEY5="1-esx4-64-tul-corp"
    ;;
  sjc1virt*)
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
    exit 1
    ;;
esac

echo "Proxy Server: $PROXY"
echo "RHEL5 Key:    $SW_KEY5"
echo
echo "RHEL6 complains if you import keys you already have. That is fine."
echo "========================================"

# Import GPG keys; some may already be installed — errors can be ignored
for key_url in \
  "http://$PROXY/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm" \
  "http://$PROXY/pub/RPM-GPG-KEY-redhat-release" \
  "http://$PROXY/pub/RPM-GPG-KEY-EPEL" \
  "http://$PROXY/pub/RPM-GPG-KEY-EPEL-6" \
  "http://$PROXY/pub/RPM-GPG-KEY-spacewalk" \
  "http://$PROXY/pub/RPM-GPG-KEY-spacewalk-2010" \
  "http://$PROXY/pub/RPM-GPG-KEY-spacewalk-2012" \
  "http://$PROXY/pub/SPACEWALK-CLIENT-TOOLS-RPM-GPG-KEY" \
  "http://$PROXY/pub/RPM-GPG-KEY-ROVI-ITLINUX"
do
  if [[ "$key_url" == *.rpm ]]; then
    rpm --force -i "$key_url" || true
  else
    rpm --import "$key_url" || true
  fi
done

# Install necessary packages
yum -y install yum-rhn-plugin rhn-setup wget rsync

# Start and verify messagebus service
if ! /sbin/service messagebus status >/dev/null 2>&1; then
  /sbin/service messagebus start
  if ! /sbin/service messagebus status >/dev/null 2>&1; then
    echo "Messagebus won't start"
    exit 1
  fi
fi

# Start and verify haldaemon service (do not fail if it can't start)
if ! /sbin/service haldaemon status >/dev/null 2>&1; then
  /sbin/service haldaemon start
  if ! /sbin/service haldaemon status >/dev/null 2>&1; then
    echo "Warning: Haldaemon won't start"
    # continue without exiting
  fi
fi

# Fix path in up2date config
perl -pi -e 's|/usr/share/rhn/RHNS-CA-CERT|/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT|' /etc/sysconfig/rhn/up2date

echo

# Check registration systemid file and validate hostname presence
if [[ -e /etc/sysconfig/rhn/systemid ]]; then
  if ! grep -qF "$HOST" /etc/sysconfig/rhn/systemid; then
    echo "Registration appears invalid!"
    echo "Clearing existing data..."
    echo
    rm -f /etc/sysconfig/rhn/systemid /etc/sysconfig/rhn/osad-auth.conf
  else
    echo "This system is already registered!"
    echo "To re-register, you must remove /etc/sysconfig/rhn/systemid"
    echo
  fi
fi

# Proceed based on RHEL version detection
if grep -q 'Tikanga' /etc/redhat-release; then
  # RHEL 5 path
  if [[ ! -e /etc/sysconfig/rhn/systemid ]]; then
    echo "Registering RHEL5 (Tikanga)"
    /usr/sbin/rhnreg_ks --force --serverUrl="http://$PROXY/XMLRPC" --activationkey="$SW_KEY5"
  fi

  # Enable and configure RHN plugin
  perl -pi -e 's/enabled.*=.*$/enabled = 1/' /etc/yum/pluginconf.d/rhnplugin.conf

  # Install additional Spacewalk clients and tools
  yum -y install 'rhncfg*' osad

  # Enable and start daemons
  /sbin/chkconfig osad on
  /sbin/chkconfig rhnsd on
  /sbin/service rhnsd restart
  /sbin/service osad restart
fi
