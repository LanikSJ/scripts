#!/usr/bin/env bash
# This Script Will Check If PR Checks Complete Then Squash and Merge
# ./script.sh <pr number>

# Check if a PR number is provided
if [ -z "$1" ]; then
  echo "ℹ️ No PR number provided. Listing mergeable PRs:"
  gh pr list --state open --json number,title,mergeStateStatus --jq '.[] | select(.mergeStateStatus == "CLEAN" or .mergeStateStatus == "HAS_UNMERGED_COMMITS") | "\(.number)\t\(.title)"'
  exit 0
fi

PR_NUMBER="$1"

# Check if the provided PR is mergeable
MERGE_STATE=$(gh pr view "$PR_NUMBER" --json mergeStateStatus --jq '.mergeStateStatus')

if [ "$MERGE_STATE" != "CLEAN" ] && [ "$MERGE_STATE" != "HAS_UNMERGED_COMMITS" ]; then
  echo "❌ PR #$PR_NUMBER is not in a mergeable state. Current state: $MERGE_STATE"
  echo "ℹ️ Listing other mergeable PRs:"
  gh pr list --state open --json number,title,mergeStateStatus --jq '.[] | select(.mergeStateStatus == "CLEAN" or .mergeStateStatus == "HAS_UNMERGED_COMMITS") | "\(.number)\t\(.title)"'
  exit 1
fi

echo "👀 Watching PR #$PR_NUMBER checks..."
if ! gh pr checks "$PR_NUMBER" --watch -i 5; then
  echo "❌ Error: PR checks failed or could not be monitored for PR #$PR_NUMBER."
  exit 1
fi

echo "✅ PR checks completed. Attempting to squash and merge PR #$PR_NUMBER..."
if ! gh pr merge "$PR_NUMBER" -s -d --auto; then
  echo "❌ Error: Failed to merge PR #$PR_NUMBER."
  exit 1
fi

echo "🎉 Successfully squashed and merged PR #$PR_NUMBER."
