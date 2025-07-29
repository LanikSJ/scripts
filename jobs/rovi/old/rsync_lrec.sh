#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="amgsjlrec01"
REMOTE_USER="root"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"

echo "Ensuring SSH key exists and is uploaded to ${REMOTE_USER}@${REMOTE_HOST}"

# Check if SSH key exists, if not, generate it non-interactively
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Generating new SSH key at $SSH_KEY_PATH (type: ed25519, no passphrase)"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""
else
    echo "SSH key already exists at $SSH_KEY_PATH"
fi

# Upload SSH public key using ssh-copy-id for robustness.
# This command might prompt for a password if it's the first connection or if passwordless SSH is not yet configured.
echo "Uploading SSH public key to ${REMOTE_USER}@${REMOTE_HOST} using ssh-copy-id..."
ssh-copy-id -i "$SSH_PUB_KEY_PATH" "${REMOTE_USER}@${REMOTE_HOST}"
echo "SSH key upload complete."

echo "Rsync'ing data from ${REMOTE_HOST}"

# Rsync /opt/recog_env/ excluding logs
REMOTE_RECOG_ENV_PATH="/opt/recog_env/"
LOCAL_RECOG_ENV_PATH="/opt/recog_env/"
echo "Rsync'ing ${REMOTE_HOST}:${REMOTE_RECOG_ENV_PATH} (excluding logs) to ${LOCAL_RECOG_ENV_PATH}"
rsync -avz "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_RECOG_ENV_PATH}" --exclude logs "${LOCAL_RECOG_ENV_PATH}"

# Rsync /home/fingerprint/signatures*
REMOTE_SIGNATURES_PATH="/home/fingerprint/signatures*"
LOCAL_SIGNATURES_PATH="/home/fingerprint/"
echo "Rsync'ing ${REMOTE_HOST}:${REMOTE_SIGNATURES_PATH} to ${LOCAL_SIGNATURES_PATH}"
rsync -avz "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SIGNATURES_PATH}" "${LOCAL_SIGNATURES_PATH}"

echo "All done"
