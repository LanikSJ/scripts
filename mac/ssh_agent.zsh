#!/usr/bin/env zsh
# Improved: Robust SSH agent loader for all keys in ~/.ssh

export HOSTNAME=$(hostname)
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.$HOSTNAME.sock"

# Function to check if ssh-agent is running and using the correct socket
function ensure_agent() {
    if [[ ! -S $SSH_AUTH_SOCK ]] || ! pgrep -u "$USER" ssh-agent >/dev/null; then
        echo "Starting new ssh-agent..."
        rm -f "$SSH_AUTH_SOCK"
        eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)" >/dev/null
    fi
}

# Function to add all private keys in ~/.ssh
function add_keys() {
    local added=0
    for key in "$HOME"/.ssh/id_*; do
        [[ -f $key && ! $key =~ \.pub$ ]] || continue
        if grep -q "PRIVATE KEY" "$key"; then
            ssh-add -l | grep -q "$key" || ssh-add "$key" && ((added++))
        fi
    done
    if (( added > 0 )); then
        echo "$added SSH key(s) added."
    else
        echo "No new SSH keys added."
    fi
}

ensure_agent
add_keys
