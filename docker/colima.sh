#!/usr/bin/env bash
# 🐳🔒 Improved: Add custom certificates to Colima with safety and idempotence

set -euo pipefail

# 📁 Variables
COLIMA_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/colima/default"
CERTS_DIR="$COLIMA_CONF_DIR/.ca-certificates"
COLIMA_YAML="$COLIMA_CONF_DIR/colima.yaml"
ROOT_CERTS="$CERTS_DIR/root_certs.pem"

# 📂 Ensure Colima config directory exists
mkdir -p "$CERTS_DIR"

# 📜 Export certificates from Keychain
echo "🔑 Exporting system certificates..."
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$ROOT_CERTS"
security find-certificate -a -p /Library/Keychains/System.keychain >> "$ROOT_CERTS"

# 💾 Backup existing colima.yaml if it exists
if [[ -f "$COLIMA_YAML" ]]; then
    cp "$COLIMA_YAML" "$COLIMA_YAML.bak.$(date +%s)"
fi

# 🧹 Remove any existing provision block to avoid duplicates
if [[ -f "$COLIMA_YAML" ]]; then
    awk '/^provision:/ {flag=1} flag && /^ *[^- ]/ {flag=0} !flag || !/^provision:/' "$COLIMA_YAML" > "$COLIMA_YAML.tmp" && mv "$COLIMA_YAML.tmp" "$COLIMA_YAML"
fi

# ➕ Append new provision block
cat << EOF >> "$COLIMA_YAML"
provision:
  - mode: system
    script: |
      CERTS="${CERTS_DIR}"
      cp -aR \${CERTS}/* /usr/local/share/ca-certificates/
      update-ca-certificates
      systemctl daemon-reload
      systemctl restart docker
EOF

# 🔄 Restart Colima
echo "🔄 Restarting Colima..."
colima stop || true
colima start

echo -e "\n✅ Certificates exported and Colima restarted successfully.\n"
