#!/usr/bin/env bash
# Script to update all Homebrew casks
# Refactored for better error handling, configurability, and maintainability

set -euo pipefail

# Configuration
UPDATE_ICON="🔄"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if brew subcommand exists
brew_subcommand_exists() {
    brew "$1" --help >/dev/null 2>&1
}

# Function to perform the update
update_casks() {
    local cmd="brew cu -ay"

    echo "${UPDATE_ICON} Updating all Homebrew casks..."
    if ! eval "$cmd"; then
        echo "❌ Error: Failed to update Homebrew casks" >&2
        return 1
    fi

    echo "${UPDATE_ICON} Cleaning up..."
    if ! brew cleanup -s --prune=1; then
        echo "⚠️  Warning: Cleanup failed, but continuing..." >&2
    fi

    echo "${UPDATE_ICON} Homebrew cask update completed!"
}

# Main execution
main() {
    # Check prerequisites
    if ! command_exists brew; then
        echo "❌ Error: Homebrew is not installed or not in PATH" >&2
        exit 1
    fi

    if ! brew_subcommand_exists cu; then
        echo "❌ Error: brew-cask-upgrade is not installed. Install with: brew tap buo/cask-upgrade" >&2
        exit 1
    fi

    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  Warning: This script is designed for macOS" >&2
    fi

    update_casks
}

main "$@"
