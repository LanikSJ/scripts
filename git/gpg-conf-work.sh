#!/usr/bin/env bash
# Script to configure Git user information and signing key for work repositories
# Author: Ilan Erenstein

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration variables
GIT_NAME="Ilan Erenstein"
GIT_EMAIL=""
GIT_SIGNING_KEY=""
ORIGINAL_DIR="$(pwd)"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed. Please install Git and try again."
    exit 1
fi

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
    
    # Find all organization directories directly under the base directory
    local org_dirs=()
    while IFS= read -r org_dir; do
        org_dirs+=("$org_dir")
    done < <(find "$base_dir" -mindepth 1 -maxdepth 1 -type d)
    
    # If no organization directories found
    if [[ ${#org_dirs[@]} -eq 0 ]]; then
        echo "ℹ️  No organization directories found in $base_dir"
        return 0
    fi
    
    # Process each organization directory
    for org_dir in "${org_dirs[@]}"; do
        echo "🏢 Processing organization: $(basename "$org_dir")"
        
        # Find all repositories in the organization directory
        local repos=()
        while IFS= read -r repo; do
            repos+=("$repo")
        done < <(find "$org_dir" -mindepth 1 -maxdepth 1 -type d)
        
        # Configure git settings for each repository
        for repo in "${repos[@]}"; do
            local repo_name
            repo_name=$(basename "$repo")
            echo "  📁 Configuring repository: $repo_name"
            
            # Change to repository directory and configure git
            if ! cd "$repo" 2>/dev/null; then
                echo "  ❌ Failed to access repository: $repo"
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
    done
    
    return 0
}

# Main script execution
echo "🚀 Starting Git configuration for work repositories..."

# Configure BitBucket repositories
configure_git_repos "$HOME/BitBucket" "BitBucket"

# Configure GitLab repositories
configure_git_repos "$HOME/GitLab" "GitLab"

# Return to the original directory
cd "$ORIGINAL_DIR" || echo "⚠️  Warning: Could not return to original directory."

echo "✨ Git configuration completed successfully!"
