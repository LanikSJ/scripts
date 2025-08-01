#!/opt/homebrew/bin/bash

# 🚇 mctunnel-start.sh - Start mctunnel with passwords from Bitwarden vault
# 🔐 This script uses Bitwarden CLI to retrieve passwords and start mctunnel connections

set -euo pipefail

# 🎨 Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 🎯 Icons
readonly ERROR="❌"
readonly SUCCESS="✅"
readonly INFO="ℹ️"
readonly WARNING="⚠️"
readonly TUNNEL="🚇"
readonly KEY="🔑"
readonly LOCK="🔒"
readonly UNLOCK="🔓"
readonly SEARCH="🔍"
readonly GEAR="⚙️"
readonly ROCKET="🚀"
readonly SHIELD="🛡️"

# ⚙️ Configuration
# shellcheck disable=SC2155
readonly SCRIPT_NAME="$(basename "$0")"
readonly BW_CLI="bw"
readonly MCTUNNEL_CMD="/opt/homebrew/bin/mctunnel"

# Default tunnel types (can be overridden by command line arguments)
DEFAULT_TUNNELS=("eagle" "merlin")

# 🖨️ Function to print colored output
print_message() {
    local color="$1"
    local icon="$2"
    local message="$3"
    echo -e "${color}${icon}${NC} ${message}"
}

# 🔍 Function to check if required tools are installed
check_dependencies() {
    print_message "$BLUE" "$GEAR" "Checking dependencies..."
    
    # Check if Bitwarden CLI is installed
    if ! command -v "$BW_CLI" >/dev/null 2>&1; then
        print_message "$RED" "$ERROR" "Bitwarden CLI not found. Please install it first:"
        echo "  📦 brew install bitwarden-cli"
        exit 1
    fi
    
    # Check if mctunnel is installed
    if [[ ! -f "$MCTUNNEL_CMD" ]]; then
        print_message "$RED" "$ERROR" "mctunnel not found at $MCTUNNEL_CMD"
        exit 1
    fi
    
    print_message "$GREEN" "$SUCCESS" "All dependencies found"
}

# 🔐 Function to check Bitwarden session status
check_bw_session() {
    print_message "$BLUE" "$SEARCH" "Checking Bitwarden session status..."
    
    # Check if already logged in and unlocked
    if bw status --quiet 2>/dev/null | grep -q '"status":"unlocked"'; then
        print_message "$GREEN" "$UNLOCK" "Bitwarden vault is already unlocked"
        return 0
    fi
    
    # Check if logged in but locked
    if bw status --quiet 2>/dev/null | grep -q '"status":"locked"'; then
        print_message "$YELLOW" "$LOCK" "Bitwarden vault is locked. Please unlock it:"
        echo "  🔓 Run: export BW_SESSION=\$(bw unlock --raw)"
        exit 1
    fi
    
    # Not logged in
    print_message "$YELLOW" "$WARNING" "Not logged into Bitwarden. Please login first:"
    echo "  🔑 Run: bw login"
    echo "  🔓 Then: export BW_SESSION=\$(bw unlock --raw)"
    exit 1
}

# 🔑 Function to retrieve password from Bitwarden
get_password_from_bw() {
    local item_name="$1"
    local password
    
    print_message "$BLUE" "$SEARCH" "Retrieving password for '$item_name' from Bitwarden..."
    
    # Try to get the password
    if password=$(bw get password "$item_name" 2>/dev/null); then
        print_message "$GREEN" "$SUCCESS" "Password retrieved successfully"
        echo "$password"
    else
        print_message "$RED" "$ERROR" "Failed to retrieve password for '$item_name'"
        print_message "$YELLOW" "$WARNING" "Make sure the item exists in your Bitwarden vault"
        return 1
    fi
}

# 🔐 Function to get SSH key passphrase from Bitwarden
get_ssh_passphrase() {
    local key_name="$1"
    local passphrase
    
    print_message "$BLUE" "$KEY" "Retrieving SSH key passphrase for '$key_name'..."
    
    # Try to get the passphrase (could be stored as a secure note or password)
    if passphrase=$(bw get password "$key_name" 2>/dev/null); then
        print_message "$GREEN" "$SUCCESS" "SSH key passphrase retrieved"
        echo "$passphrase"
    else
        print_message "$YELLOW" "$WARNING" "No passphrase found for '$key_name' - assuming key has no passphrase"
        echo ""
    fi
}

# 🚇 Function to start mctunnel with proper bash version
start_mctunnel() {
    local tunnel_type="$1"
    
    print_message "$BLUE" "$ROCKET" "Starting mctunnel for $tunnel_type..."
    
    # Use the proper bash version to run mctunnel
    if BASH=/opt/homebrew/bin/bash /opt/homebrew/bin/bash "$MCTUNNEL_CMD" start "$tunnel_type"; then
        print_message "$GREEN" "$SUCCESS" "mctunnel started successfully for $tunnel_type"
    else
        print_message "$RED" "$ERROR" "Failed to start mctunnel for $tunnel_type"
        return 1
    fi
}

# 📊 Function to check mctunnel status
check_mctunnel_status() {
    print_message "$BLUE" "$TUNNEL" "Checking mctunnel status..."
    
    # Use proper bash version to check status
    BASH=/opt/homebrew/bin/bash /opt/homebrew/bin/bash "$MCTUNNEL_CMD" status
}

# 🔧 Function to setup SSH agent with keys and passphrases
setup_ssh_agent() {
    print_message "$BLUE" "$GEAR" "Setting up SSH agent..."
    
    # Start SSH agent if not running
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        print_message "$YELLOW" "$WARNING" "SSH agent not running. Starting SSH agent..."
        eval "$(ssh-agent -s)"
    fi
    
    # Common SSH key locations for CrowdStrike environments
    local ssh_keys=(
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/crowdstrike_rsa"
        "$HOME/.ssh/eagle_rsa"
        "$HOME/.ssh/merlin_rsa"
    )
    
    for key_path in "${ssh_keys[@]}"; do
        if [[ -f "$key_path" ]]; then
            local key_name
            key_name=$(basename "$key_path")
            
            print_message "$BLUE" "$KEY" "Found SSH key: $key_path"
            
            # Try to get passphrase from Bitwarden
            local passphrase
            passphrase=$(get_ssh_passphrase "ssh-$key_name" || echo "")
            
            # Add key to SSH agent
            if [[ -n "$passphrase" ]]; then
                print_message "$BLUE" "$SHIELD" "Adding key with passphrase to SSH agent..."
                expect <<EOF
spawn ssh-add "$key_path"
expect "Enter passphrase for $key_path:"
send "$passphrase\r"
expect eof
EOF
            else
                print_message "$BLUE" "$KEY" "Adding key to SSH agent..."
                ssh-add "$key_path" 2>/dev/null || true
            fi
        fi
    done
}

# 📖 Function to display usage
usage() {
    cat << EOF
🚇 Usage: $SCRIPT_NAME [OPTIONS] [TUNNEL_TYPES...]

Start mctunnel with passwords retrieved from Bitwarden vault.

⚙️ OPTIONS:
    -h, --help          Show this help message
    -s, --status        Check mctunnel status only
    -c, --check         Run dependency checks only
    --setup-ssh         Setup SSH agent with keys from Bitwarden

🚇 TUNNEL_TYPES:
    eagle               Start Eagle tunnel 🦅
    merlin              Start Merlin tunnel 🧙‍♂️
    multicloud          Start Multicloud tunnel ☁️
    team                Start Team tunnel 👥

If no tunnel types are specified, defaults to: ${DEFAULT_TUNNELS[*]}

💡 EXAMPLES:
    $SCRIPT_NAME                    # Start default tunnels (eagle, merlin)
    $SCRIPT_NAME eagle              # Start only Eagle tunnel
    $SCRIPT_NAME eagle merlin       # Start Eagle and Merlin tunnels
    $SCRIPT_NAME --status           # Check status only
    $SCRIPT_NAME --setup-ssh        # Setup SSH agent with keys

🔐 BITWARDEN SETUP:
    This script expects the following items in your Bitwarden vault:
    - SSH key passphrases named: ssh-<keyname> (e.g., ssh-id_rsa, ssh-eagle_rsa)
    - Any other passwords needed for tunnel authentication

    Before running this script:
    1. 🔑 Login to Bitwarden: bw login
    2. 🔓 Unlock vault: export BW_SESSION=\$(bw unlock --raw)

EOF
}

# 🚀 Main function
main() {
    local tunnels=()
    local status_only=false
    local check_only=false
    local setup_ssh_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -s|--status)
                status_only=true
                shift
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            --setup-ssh)
                setup_ssh_only=true
                shift
                ;;
            eagle|merlin|multicloud|team)
                tunnels+=("$1")
                shift
                ;;
            *)
                print_message "$RED" "$ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Set default tunnels if none specified
    if [[ ${#tunnels[@]} -eq 0 && "$status_only" == false && "$setup_ssh_only" == false ]]; then
        tunnels=("${DEFAULT_TUNNELS[@]}")
    fi
    
    print_message "$BLUE" "$INFO" "Starting $SCRIPT_NAME..."
    
    # Check dependencies
    check_dependencies
    
    if [[ "$check_only" == true ]]; then
        print_message "$GREEN" "$SUCCESS" "Dependency check completed"
        exit 0
    fi
    
    # Check Bitwarden session (unless only checking status)
    if [[ "$status_only" == false ]]; then
        check_bw_session
    fi
    
    # Setup SSH agent if requested
    if [[ "$setup_ssh_only" == true ]]; then
        setup_ssh_agent
        print_message "$GREEN" "$SUCCESS" "SSH agent setup completed"
        exit 0
    fi
    
    # Check status only if requested
    if [[ "$status_only" == true ]]; then
        check_mctunnel_status
        exit 0
    fi
    
    # Setup SSH agent before starting tunnels
    setup_ssh_agent
    
    # Start tunnels
    local failed_tunnels=()
    for tunnel in "${tunnels[@]}"; do
        if ! start_mctunnel "$tunnel"; then
            failed_tunnels+=("$tunnel")
        fi
    done
    
    # Report results
    if [[ ${#failed_tunnels[@]} -eq 0 ]]; then
        print_message "$GREEN" "$SUCCESS" "All tunnels started successfully!"
        echo
        check_mctunnel_status
    else
        print_message "$RED" "$ERROR" "Failed to start tunnels: ${failed_tunnels[*]}"
        exit 1
    fi
}

# 🔍 Check if expect is available (needed for SSH key passphrases)
if ! command -v expect >/dev/null 2>&1; then
    print_message "$YELLOW" "$WARNING" "expect not found. SSH key passphrases will need to be entered manually."
    print_message "$BLUE" "$INFO" "To install expect: 📦 brew install expect"
fi

# 🚀 Run main function with all arguments
main "$@"
