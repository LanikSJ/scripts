#!/usr/bin/env bash
# Script to configure Git user information and signing key for various repositories
# Author: LanikSJ

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration variables
GIT_NAME=""
GIT_EMAIL=""
GIT_SIGNING_KEY=""
ORIGINAL_DIR="$(pwd)"

# Keychain service names (adjust if yours are different)
GITHUB_EMAIL_SERVICE="github-email"
GITHUB_SIGNING_KEY_SERVICE="github-signing-key"
WORK_EMAIL_SERVICE="git-work-email"
WORK_SIGNING_KEY_SERVICE="git-work-signing-key"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed. Please install Git and try again."
    exit 1
fi

# Function to retrieve credentials from macOS Keychain
get_keychain_credential() {
    local service_name="$1"
    local account_name="$2" # Typically the email address or a descriptive name
    security find-generic-password -s "$service_name" -a "$account_name" -w 2>/dev/null
}

# Function to configure git settings in repositories
configure_git_repos() {
    local base_dir="$1"
    local base_name="$2"
    
    # Check if the directory exists
    if [[ ! -d "$base_dir" ]]; then
        echo "⚠️  Directory $base_dir does not exist. Skipping."
        return 1
    fi
    
    echo "🔧 Processing $base_name repositories..."
    
    # Use find to properly handle directory names with spaces
    find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
        local repo_name
        repo_name=$(basename "$dir")
        echo "  📁 Configuring repository: $repo_name"
        
        # Change to repository directory and configure git
        if ! cd "$dir" 2>/dev/null; then
            echo "  ❌ Failed to access repository: $dir"
            continue
        fi
        
        # Check if it's a Git repository
        if [ ! -d ".git" ] && ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "  ⚠️  Warning: $repo_name is not a Git repository. Skipping."
            cd "$ORIGINAL_DIR" || echo "⚠️  Warning: Could not return to original directory."
            continue
        fi
        
        # Configure git settings
        git config user.name "$GIT_NAME"
        git config user.email "$GIT_EMAIL"
        git config user.signingkey "$GIT_SIGNING_KEY"
        echo "  ✅ Successfully configured Git settings for $repo_name"
        
        # Return to original directory
        cd "$ORIGINAL_DIR" || echo "⚠️  Warning: Could not return to original directory."
    done
    
    return 0
}

# Main script execution
echo "🚀 Starting Git configuration..."

if [[ -z "$1" ]]; then
    echo "Usage: $0 [github|work]"
    exit 1
fi

PROFILE="$1"

case "$PROFILE" in
    github)
        echo "⚙️ Configuring for GitHub profile..."
        GIT_NAME="LanikSJ" # Assuming a fixed name for GitHub
        
        # Retrieve email and signing key from keychain
        GIT_EMAIL=$(get_keychain_credential "$GITHUB_EMAIL_SERVICE" "github")
        GIT_SIGNING_KEY=$(get_keychain_credential "$GITHUB_SIGNING_KEY_SERVICE" "github")
        
        if [[ -z "$GIT_EMAIL" || -z "$GIT_SIGNING_KEY" ]]; then
            echo "❌ Error: Could not retrieve GitHub email or signing key from keychain."
            echo "Please ensure you have entries for '$GITHUB_EMAIL_SERVICE' and '$GITHUB_SIGNING_KEY_SERVICE' in your keychain."
            exit 1
        fi
        
        configure_git_repos "$HOME/GitHub/LanikSJ" "GitHub"
        configure_git_repos "/opt/homebrew/Library/Taps/homebrew" "Homebrew"
        ;;
    work)
        echo "⚙️ Configuring for Work profile..."
        GIT_NAME="LanikSJ" # Assuming a fixed name for Work
        
        # Retrieve email and signing key from keychain
        GIT_EMAIL=$(get_keychain_credential "$WORK_EMAIL_SERVICE" "work")
        GIT_SIGNING_KEY=$(get_keychain_credential "$WORK_SIGNING_KEY_SERVICE" "work")
        
        if [[ -z "$GIT_EMAIL" || -z "$GIT_SIGNING_KEY" ]]; then
            echo "❌ Error: Could not retrieve Work email or signing key from keychain."
            echo "Please ensure you have entries for '$WORK_EMAIL_SERVICE' and '$WORK_SIGNING_KEY_SERVICE' in your keychain."
            exit 1
        fi
        
        configure_git_repos "$HOME/BitBucket" "BitBucket"
        configure_git_repos "$HOME/GitLab" "GitLab"
        ;;
    *)
        echo "❌ Invalid profile: $PROFILE. Use 'github' or 'work'."
        exit 1
        ;;
esac

# Return to the original directory
cd "$ORIGINAL_DIR" || echo "⚠️  Warning: Could not return to original directory."

echo "✨ Git configuration completed successfully!"
