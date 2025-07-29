#!/bin/bash
set -e

ARCH=$(uname -m)
BASE_URL="http://192.168.0.61/redhat/os/4AS/${ARCH}/u4/RedHat/RPMS"
RPM_DIR="/tmp/rpms"

if [ "$ARCH" = "i686" ] || [ "$ARCH" = "x86_64" ]; then
    echo "Detected architecture: $ARCH"
    mkdir -p "$RPM_DIR"

    # Download RPMs
    wget "${BASE_URL}/openldap-clients-2.2.13-6.4E.${ARCH}.rpm" -P "$RPM_DIR"
    wget "${BASE_URL}/openldap-2.2.13-6.4E.${ARCH}.rpm" -P "$RPM_DIR"
    wget "${BASE_URL}/nss_ldap-226-13.${ARCH}.rpm" -P "$RPM_DIR"
    wget "${BASE_URL}/authconfig-4.6.10-rhel4.3.${ARCH}.rpm" -P "$RPM_DIR"

    # Install RPMs
    rpm -ivh "$RPM_DIR"/*.rpm

    # Configure authentication
    system-config-authentication --enableldap --enableldapauth --ldapserver=192.168.5.220 --ldapbasedn=dc=macrovisioncolo,dc=com --enablecache --update

    # Add sudoers_base to ldap.conf
    echo "sudoers_base   ou=SUDOers,dc=macrovisioncolo,dc=com" >> /etc/ldap.conf

    # Download and apply patch
    wget http://192.168.0.61/nsswitch.patch -P /tmp
    patch -p0 < /tmp/nsswitch.patch
else
    echo "Unsupported architecture: $ARCH. Nothing to do."
fi
