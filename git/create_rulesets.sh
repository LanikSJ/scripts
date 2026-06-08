#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Script: create_rulesets.sh
# Purpose: Create a GitHub ruleset for each repository belonging to
#          the specified GitHub account (user or organization) that
#          restricts deletions on the default branch. The ruleset is
#          named after the default branch and is only created if it
#          does not already exist.
# ------------------------------------------------------------

# ----- Configuration -----
ORG="LanikSJ"
# The GitHub CLI (gh) uses the authentication configured via `gh auth login`.
# Ensure you are logged in (`gh auth status`) before running this script.
# No explicit token variable is required.

# Log file location – will be placed in the directory where the script is executed.
LOGFILE="$(pwd)/ruleset_creation.log"
# ------------------------

log(){
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') $*" | tee -a "$LOGFILE"
}

# Detect whether ORG refers to an organization or a user.
# Returns the appropriate API prefix ("orgs" or "users").
function detect_api_prefix() {
  # Try organization endpoint first.
  if gh api -X GET "/orgs/${ORG}" >/dev/null 2>&1; then
    echo "orgs"
    return
  fi
  # Fallback to user endpoint.
  if gh api -X GET "/users/${ORG}" >/dev/null 2>&1; then
    echo "users"
    return
  fi
  # Neither succeeded – abort with clear message.
  log "ERROR: Unable to determine whether '${ORG}' is a user or organization."
  exit 1
}

API_PREFIX=$(detect_api_prefix)
log "Using API prefix: $API_PREFIX"

# ------------------------------------------------------------
# 1. List all repositories for the determined entity (handles pagination).
repos_json=$(gh api -X GET "/${API_PREFIX}/${ORG}/repos?per_page=100" --paginate)

# Process each repository individually.
printf "%s" "$repos_json" | jq -c '.[]' | while read -r repo; do
  full_name=$(echo "$repo" | jq -r '.full_name')
  default_branch=$(echo "$repo" | jq -r '.default_branch')
  log "Processing $full_name (default branch: $default_branch)"

  # ------------------------------------------------------------
  # 2. Retrieve existing rulesets for the repository.
  existing_id=$(gh api -X GET "/repos/${full_name}/rulesets" \
                 --jq ".[] | select(.name==\"${default_branch}\") | .id" || true)

  if [[ -n $existing_id ]]; then
    log "  Ruleset already exists (ID: $existing_id). Skipping."
    continue
  fi

  # ------------------------------------------------------------
  # 3. Create the ruleset (delete protection only).
    payload=$(jq -n \
      --arg name "$default_branch" \
      --arg target "branch" \
      --arg enforcement "active" \
      --arg ref "refs/heads/${default_branch}" \
      --argjson rules '[{"type":"deletion","enabled":true}]' \
      '{name:$name, target:$target, enforcement:$enforcement, rules:$rules}')
    # Use the GitHub CLI to obtain a token (requires gh auth login)
    TOKEN=$(gh auth token)
    response=$(curl -sSL -X POST \
      -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "Content-Type: application/json" \
      -d "$payload" "https://api.github.com/repos/${full_name}/rulesets")

  if echo "$response" | jq -e '.id' > /dev/null; then
    log "  Created ruleset successfully."
  else
    err=$(echo "$response" | jq -r '.message')
    log "  Failed to create ruleset: $err"
  fi
done

log "--- Summary completed $(date -u +'%Y-%m-%dT%H:%M:%SZ') ---"
