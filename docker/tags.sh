#!/usr/bin/env bash
# 🐳🔖 tags  --  List all tags for a Docker image on Docker Hub, with optional filtering

set -euo pipefail

if ! command -v jq &>/dev/null
then
  echo "❌ jq is required but not installed. Please install jq."
  exit 2
fi

# Check if at least one argument is provided
if [[ $# -lt 1 ]]
then
  cat << HELP

tags  --  list all tags for a Docker image on a remote registry.

EXAMPLE:
    - list all tags for ubuntu:
       tags ubuntu

    - list all php tags containing apache:
       tags php apache

HELP
fi

tags=$(curl https://hub.docker.com/v2/repositories/"$1"/tags | jq -r '.results.[].name')

if [[ -n "$2" ]]
then
  tags=$(echo "${tags}" | grep "$2")
fi

echo "${tags}"
