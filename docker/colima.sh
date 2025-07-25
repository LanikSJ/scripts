#!/usr/bin/env bash
# This script adds custom certificates to colima

# Remove Old Config Directory
rm -rf ~/.colima

# Create Directories
mkdir -p "${XDG_CONFIG_HOME}"/colima/default/.ca-certificates

# Export Certificates from Keychain
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "${XDG_CONFIG_HOME}"/colima/default/.ca-certificates/root_certs.pem
security find-certificate -a -p /Library/Keychains/System.keychain >> "${XDG_CONFIG_HOME}"/colima/default/.ca-certificates/root_certs.pem

# Update Default Colima Config
sed -i "s/provision: \[\]/# provision: \[\]/" "${XDG_CONFIG_HOME}"/colima/default/colima.yaml

# Create or Update Colima Configuration
cat << EOF >> "${XDG_CONFIG_HOME}"/colima/default/colima.yaml
provision:
  - mode: system
    script: |
      CERTS="${XDG_CONFIG_HOME}/colima/default/.ca-certificates"
      cp -aR \${CERTS}/* /usr/local/share/ca-certificates/
      update-ca-certificates
      systemctl daemon-reload
      systemctl restart docker
EOF

# Stop Colima
colima stop

# Start Colima with the New Configuration
colima start

echo && echo "Certificates Exported and Colima Configured and Restarted!"
