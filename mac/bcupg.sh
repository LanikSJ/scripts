#!/usr/bin/env bash
# Script to update all Homebrew casks

# Icon for update process
UPDATE_ICON="🔄"

echo "${UPDATE_ICON} Updating all Homebrew casks..."
brew cu -ay --include-mas
brew cleanup -s --prune=1
echo "${UPDATE_ICON} Homebrew cask update completed!"
