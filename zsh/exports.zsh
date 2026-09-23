# WARNING: Avoid committing sensitive information like API tokens to version control.
# Sensitive tokens are retrieved from macOS Keychain for security.
# Store tokens using: security add-generic-password -s "ServiceName" -a "AccountName" -w "token_value"

# Set color scheme on Mac OS X
export CLICOLOR="1"
export LSCOLORS="ExFxCxDxBxegedabagacad"

# Prevent Oh My Zsh from setting LS_COLORS (overrides eza theme)
export DISABLE_LS_COLORS="true"
unset LS_COLORS

# GitHub Homebrew Token
export HOMEBREW_EDITOR="vim"
export HOMEBREW_NO_ENV_HINTS="1"
export HOMEBREW_BUNDLE_NO_LOCK="1"
export HOMEBREW_INSTALL_CLEANUP="1"
export HOMEBREW_FORCE_BREWED_CURL="1"
export HOMEBREW_FORCE_VENDOR_RUBY="1"
export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -s "Homebrew" -a "GitHub_API_Token" -w 2>/dev/null || echo "")
export HOMEBREW_CLEANUP_MAX_AGE_DAYS="7"
export HOMEBREW_NO_ASK="1"

# AWS Pagination
export AWS_PAGER=""

# AWS Profile
RPROMPT="${RPROMPT//\$\(aws_prompt_info\)}"

# AWS Prompt
SHOW_AWS_PROMPT="false"

# Colima
export COLIMA_HOME="${HOME}/.colima_home"

# Docker Host
export DOCKER_HOST="unix://${COLIMA_HOME}/default/docker.sock"

# iTerm
export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX="YES"

# NPM Warnings
export NODE_OPTIONS="--disable-warning=ExperimentalWarning"

# PIP Columns
export PIP_FORMAT="columns"

# Set JAVA Home (Homebrew JDK)
export JAVA_HOME="/opt/homebrew/opt/openjdk"

# Bitwarden
export BW_SESSION=$(security find-generic-password -s "Bitwarden" -a "Session" -w 2>/dev/null || echo "")

# IPInfo.io Token
export IPINFO_TOKEN=$(security find-generic-password -s "IPInfo" -a "Token" -w 2>/dev/null || echo "")

# XDG Base Directory
#export XDG_CONFIG_HOME="${HOME}/.config"

# XML Catalog Pages
export XML_CATALOG_FILES="/opt/homebrew/etc/xml/catalog"
