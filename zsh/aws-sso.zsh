# AWS SSO (loaded by Oh My Zsh)
dev-basic-admin() {
  local account
  account=$(security find-generic-password -a "$USER" -s "aws-dev-basic-admin" -w 2>/dev/null)
  if [[ -z "$account" ]]; then
    echo "aws-dev-basic-admin not in Keychain." >&2
    return 1
  fi
  aws sso login --profile "dev_basic_admin-${account}"
}
