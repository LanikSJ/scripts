#!/bin/bash
OS_VER=$(uname -a | awk '{print $12}')
if [ $OS_VER = "i686" ] ;
then
wget http://192.168.0.61/redhat/os/4AS/i386/u4/RedHat/RPMS/openldap-clients-2.2.13-6.4E.i386.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/i386/u4/RedHat/RPMS/openldap-2.2.13-6.4E.i386.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/i386/u4/RedHat/RPMS/nss_ldap-226-13.i386.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/i386/u4/RedHat/RPMS/authconfig-4.6.10-rhel4.3.i386.rpm -P /tmp/rpms
rpm -ivh /tmp/rpms/*.rpm
system-config-authentication --enableldap --enableldapauth  --ldapserver=192.168.5.220 --ldapbasedn=dc=macrovisioncolo,dc=com --enablecache  --update
echo "sudoers_base   ou=SUDOers,dc=macrovisioncolo,dc=com" >> /etc/ldap.conf
wget http://192.168.0.61/nsswitch.patch -P /tmp
patch -p0 < /tmp/nsswitch.patch
fi
else
echo "nothing to do"
if [ $OS_VER = "x86_64" ] ;
then
wget http://192.168.0.61/redhat/os/4AS/x86_64/u4/RedHat/RPMS/openldap-2.2.13-6.4E.x86_64.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/x86_64/u4/RedHat/RPMS/openldap-clients-2.2.13-6.4E.x86_64.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/x86_64/u4/RedHat/RPMS/nss_ldap-226-13.x86_64.rpm -P /tmp/rpms
wget http://192.168.0.61/redhat/os/4AS/x86_64/u4/RedHat/RPMS/authconfig-4.6.10-rhel4.3.x86_64.rpm -P /tmp/rpms
rpm -ivh /tmp/rpms/*.rpm
system-config-authentication --enableldap --enableldapauth  --ldapserver=192.168.5.220 --ldapbasedn=dc=macrovisioncolo,dc=com --enablecache  --update
echo "sudoers_base   ou=SUDOers,dc=macrovisioncolo,dc=com" >> /etc/ldap.conf
wget http://192.168.0.61/nsswitch.patch -P /tmp
patch -p0 < /tmp/nsswitch.patch
else
echo "nothing to do"
fi
fi
