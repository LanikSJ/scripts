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
WORK_NAME_SERVICE="git-work-name"

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

# Function to check if a credential exists in macOS Keychain
check_keychain_credential() {
    local service_name="$1"
    local account_name="$2"
    # Use || true to prevent set -e from exiting on non-zero return
    security find-generic-password -s "$service_name" -a "$account_name" -w &>/dev/null || return 1
    return 0
}

# Function to show how to add credentials to macOS Keychain
show_add_credential_instructions() {
    local service_name="$1"
    local account_name="$2"
    local description="$3"
    
    echo ""
    echo "📝 To add '$description' to your macOS Keychain, run:"
    echo ""
    echo "   security add-generic-password \\"
    echo "     -s \"$service_name\" \\"
    echo "     -a \"$account_name\" \\"
    echo "     -w \"YOUR_VALUE_HERE\""
    echo ""
    echo "   Or use Keychain Access app:"
    echo "   1. Open Keychain Access (Applications > Utilities)"
    echo "   2. Click the '+' button to add a new password item"
    echo "   3. Set Keychain Item Name: \"$service_name\""
    echo "   4. Set Account Name: \"$account_name\""
    echo "   5. Enter your $description in the password field"
    echo "   6. Click 'Add'"
    echo ""
}

# Function to check all required credentials and show instructions for missing ones
check_all_credentials() {
    local missing_count=0
    
    echo "🔍 Checking required credentials in macOS Keychain..."
    echo ""
    
    # Check GitHub email
    if check_keychain_credential "$GITHUB_EMAIL_SERVICE" "github"; then
        echo "✅ Found: $GITHUB_EMAIL_SERVICE (account: github)"
    else
        echo "❌ Missing: $GITHUB_EMAIL_SERVICE (account: github)"
        show_add_credential_instructions "$GITHUB_EMAIL_SERVICE" "github" "GitHub email address"
        missing_count=$((missing_count + 1))
    fi
    
    # Check GitHub signing key
    if check_keychain_credential "$GITHUB_SIGNING_KEY_SERVICE" "github"; then
        echo "✅ Found: $GITHUB_SIGNING_KEY_SERVICE (account: github)"
    else
        echo "❌ Missing: $GITHUB_SIGNING_KEY_SERVICE (account: github)"
        show_add_credential_instructions "$GITHUB_SIGNING_KEY_SERVICE" "github" "GitHub GPG signing key"
        missing_count=$((missing_count + 1))
    fi
    
    # Check Work email
    if check_keychain_credential "$WORK_EMAIL_SERVICE" "work"; then
        echo "✅ Found: $WORK_EMAIL_SERVICE (account: work)"
    else
        echo "❌ Missing: $WORK_EMAIL_SERVICE (account: work)"
        show_add_credential_instructions "$WORK_EMAIL_SERVICE" "work" "Work email address"
        missing_count=$((missing_count + 1))
    fi
    
    # Check Work signing key
    if check_keychain_credential "$WORK_SIGNING_KEY_SERVICE" "work"; then
        echo "✅ Found: $WORK_SIGNING_KEY_SERVICE (account: work)"
    else
        echo "❌ Missing: $WORK_SIGNING_KEY_SERVICE (account: work)"
        show_add_credential_instructions "$WORK_SIGNING_KEY_SERVICE" "work" "Work GPG signing key"
        missing_count=$((missing_count + 1))
    fi
    
    echo ""
    if [[ $missing_count -eq 0 ]]; then
        echo "✨ All credentials are configured!"
        return 0
    else
        echo "⚠️  Found $missing_count missing credential(s). Please add them using the instructions above."
        return 1
    fi
}
configure_git_repos() {
    local base_dir="$1"
    local base_name="$2"
    
    # Check if the directory exists
    if [[ ! -d "$base_dir" ]]; then
        echo "⚠️ Directory $base_dir does not exist. Skipping."
        return 1
    fi
    
    echo "🔧 Processing $base_name repositories..."
    
    # Use find to properly handle directory names with spaces
    find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
        local repo_name
        repo_name=$(basename "$dir")
        echo "📁 Configuring repository: $repo_name"
        
        # Change to repository directory and configure git
        if ! cd "$dir" 2>/dev/null; then
            echo "❌ Failed to access repository: $dir"
            continue
        fi
        
        # Check if it's a Git repository
        if [ ! -d ".git" ] && ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "⚠️ Warning: $repo_name is not a Git repository. Skipping."
            cd "$ORIGINAL_DIR" || echo "⚠️ Warning: Could not return to original directory."
            continue
        fi
        
        # Configure git settings
        git config user.name "$GIT_NAME"
        git config user.email "$GIT_EMAIL"
        git config user.signingkey "$GIT_SIGNING_KEY"
        echo "✅ Successfully configured Git settings for $repo_name"
        
        # Return to original directory
        cd "$ORIGINAL_DIR" || echo "⚠️ Warning: Could not return to original directory."
    done
    
    return 0
}

# Main script execution

# Check for help option
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Git Configuration Script"
    echo "Usage: $0 [github|work|--check] [--help|-h]"
    echo ""
    echo "Options:"
    echo "  --check  Check if all required credentials exist in macOS Keychain"
    echo ""
    echo "Profiles:"
    echo "  github  Configure for GitHub profile"
    echo "  work    Configure for Work profile"
    echo ""
    echo "The script sets Git user name, email, and GPG signing key for repositories."
    echo "Credentials are retrieved from macOS Keychain."
    echo ""
    echo "For github profile:"
    echo "  - Name: LanikSJ"
    echo "  - Email: Retrieved from keychain service 'github-email'"
    echo "  - Signing Key: Retrieved from keychain service 'github-signing-key'"
    echo ""
    echo "For work profile:"
    echo "  - Name: Retrieved from keychain service 'git-work-name'"
    echo "  - Email: Retrieved from keychain service 'git-work-email'"
    echo "  - Signing Key: Retrieved from keychain service 'git-work-signing-key'"
    echo ""
    echo "Directories configured:"
    echo "  github: ~/GitHub/LanikSJ and /opt/homebrew/Library/Taps/homebrew"
    echo "  work: ~/BitBucket and ~/GitLab"
    exit 0
fi

# Check for --check option
if [[ "$1" == "--check" ]]; then
    check_all_credentials
    exit $?
fi

echo "🚀 Starting Git configuration..."

if [[ -z "$1" ]]; then
    echo "Usage: $0 [github|work|--check]"
    echo "Use '$0 --help' for more information."
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
        GIT_NAME=$(get_keychain_credential "$WORK_NAME_SERVICE" "work")
        
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
cd "$ORIGINAL_DIR" || echo "⚠️ Warning: Could not return to original directory."

echo "✨ Git configuration completed successfully!"
