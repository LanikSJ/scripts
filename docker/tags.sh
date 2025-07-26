#!/usr/bin/env bash
# 🐳🔖 List all tags for a Docker image on Docker Hub, with optional filtering

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "❌ jq is required but not installed. Please install jq."
  exit 2
fi

if [[ $# -lt 1 ]]; then
  cat << 'HELP'
🐳🔖 tags  --  List all tags for a Docker image on Docker Hub.

📦 EXAMPLES:
    - List all tags for ubuntu:
        tags ubuntu

    - List all php tags containing apache:
        tags php apache

🛠️ USAGE:
    tags <image> [filter]

HELP
  exit 1
fi

IMAGE="$1"
FILTER="${2:-}"

# 🌐 Fetch all tags (paginated)
TAGS=()
URL="https://hub.docker.com/v2/repositories/${IMAGE}/tags?page_size=100"
echo "🔎 Fetching tags for image: $IMAGE ..."
while [[ -n "$URL" ]]; do
  RESP=$(curl -fsSL "$URL")
  mapfile -t NEW_TAGS < <(echo "$RESP" | jq -r '.results[].name')
  TAGS+=("${NEW_TAGS[@]}")
  URL=$(echo "$RESP" | jq -r '.next')
  [[ "$URL" == "null" ]] && URL=""
done

# 🔍 Filter tags if a filter is provided
if [[ -n "$FILTER" ]]; then
  echo "${TAGS[@]}" | tr ' ' '\n' | grep --color=auto -i "$FILTER" || echo "⚠️ No tags found matching '$FILTER'."
else
  echo "📋 All tags for $IMAGE:"
  printf '%s\n' "${TAGS[@]}" | sort -u
fi
echo "✅ Tags fetched successfully."
