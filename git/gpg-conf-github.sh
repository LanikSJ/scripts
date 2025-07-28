#!/usr/bin/env bash
# Script to configure Git settings for GitHub, Homebrew, and GitLab repositories
# Author: LanikSJ

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration variables
GIT_NAME="LanikSJ"
GIT_EMAIL="laniksj@gmail.com"
GIT_SIGNING_KEY="C043F668DB04FD0E"
ORIGINAL_DIR="$(pwd)"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed. Please install Git and try again."
    exit 1
fi

# Function to configure Git settings
configure_git() {
    local repo_dir="$1"
    local repo_name="$2"
    
    if [ ! -d "$repo_dir" ]; then
        echo "⚠️  Warning: Directory $repo_dir does not exist. Skipping."
        return
    fi
    
    echo "🔧 Configuring Git settings for $repo_name repositories..."
    
    # Use find to properly handle directory names with spaces
    find "$repo_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
        echo "  📁 Setting up $(basename "$dir")"
        if ! cd "$dir" 2>/dev/null; then
            echo "    ⚠️  Warning: Could not access $dir. Skipping."
            continue
        fi
        
        # Check if it's a Git repository
        if [ ! -d ".git" ] && ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "    ⚠️  Warning: $dir is not a Git repository. Skipping."
            continue
        fi
        
        # Configure Git settings
        git config user.name "$GIT_NAME"
        git config user.email "$GIT_EMAIL"
        git config user.signingkey "$GIT_SIGNING_KEY"
        echo "    ✅ Successfully configured Git settings."
    done
}

# Main execution
echo "🚀 Starting Git configuration for multiple repositories..."

# Configure GitHub repositories
configure_git "$HOME/GitHub/LanikSJ" "GitHub"

# Configure Homebrew repositories
configure_git "/opt/homebrew/Library/Taps/homebrew" "Homebrew"

# Configure GitLab repositories if directory exists
configure_git "$HOME/GitLab/Lanik" "GitLab"

# Return to the original directory
cd "$ORIGINAL_DIR" || echo "⚠️  Warning: Could not return to original directory."

echo "✨ Git configuration completed successfully."
