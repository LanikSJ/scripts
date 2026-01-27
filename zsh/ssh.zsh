#!/bin/zsh
#
# SSH/Rsync/SCP Autocomplete Enhancements
# This script configures zsh completion for SSH, SCP, and Rsync commands
# with improved host/IP handling, case-insensitive matching, and visual feedback.

# Prevent multiple sourcing of this file
if [[ -n $ZSH_SSH_COMPLETION_LOADED ]]; then
  return
fi

# Highlight completion options using LS_COLORS if available
if [[ -n $LS_COLORS ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Enhanced SSH/Rsync/SCP Autocomplete Configuration
# Prioritize hosts (IP addresses and hostnames) over files in completion
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-ipaddr:ip\ address hosts:-host:host files'

# Ignore common localhost/loopback hostnames for SSH/SCP/Rsync host completion
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns \
  '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost

# Ignore invalid or local IP addresses for SSH/SCP/Rsync IP completion
# Patterns: IPv4/IPv6 addresses, localhost ranges, broadcast addresses
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns \
  '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' \
  '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Case-insensitive completion matching
# Allows matching regardless of case, with additional fuzzy matching
zstyle ':completion:*' matcher-list '' \
  'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  '+l:|?=** r:|?=**'

# Initialize zsh autocompletion system (ignore insecure files)
autoload -Uz compinit && compinit -i

# Mark this script as loaded
ZSH_SSH_COMPLETION_LOADED=1
