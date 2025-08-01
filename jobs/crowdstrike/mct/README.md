# 🚇 CrowdStrike Scripts

This directory contains scripts for CrowdStrike-specific tasks.

## 🔐 mctunnel-start.sh

A script that starts mctunnel connections with passwords retrieved from Bitwarden vault.

### ✨ Features

- **🔐 Bitwarden Integration**: Retrieves SSH key passphrases and other credentials from Bitwarden vault
- **🚇 Multiple Tunnel Support**: Can start Eagle 🦅, Merlin 🧙‍♂️, Multicloud ☁️, and Team 👥 tunnels
- **🔧 SSH Agent Management**: Automatically sets up SSH agent with keys and passphrases
- **⚙️ Bash 4.0+ Compatibility**: Uses the proper bash version to run mctunnel
- **🎨 Enhanced Visual Interface**: Colorized output with contextual icons and status indicators
- **❌✅ Comprehensive Error Handling**: Clear error checking with user-friendly messages
- **📖 Interactive Help**: Detailed usage information with visual examples

### 📋 Prerequisites

1. **🔐 Bitwarden CLI**: Install with `📦 brew install bitwarden-cli`
2. **🚇 mctunnel**: Should be installed at `/opt/homebrew/bin/mctunnel`
3. **⏱️ expect**: Install with `📦 brew install expect` (optional, for automated SSH key passphrase entry)
4. **⚙️ Bash 4.0+**: Available at `/opt/homebrew/bin/bash`

### 🚀 Setup

1. **🔑 Login to Bitwarden**:

   ```bash
   bw login
   ```

2. **🔓 Unlock your vault and set session**:

   ```bash
   export BW_SESSION=$(bw unlock --raw)
   ```

3. **🔐 Store SSH key passphrases in Bitwarden**:
   - Create items in your Bitwarden vault for SSH key passphrases
   - Name them using the pattern: `ssh-<keyname>`
   - Examples: `ssh-id_rsa`, `ssh-eagle_rsa`, `ssh-merlin_rsa`

### 💻 Usage

```bash
# Start default tunnels (eagle, merlin)
./mctunnel-start.sh

# Start specific tunnels
./mctunnel-start.sh eagle
./mctunnel-start.sh eagle merlin multicloud

# Check status only
./mctunnel-start.sh --status

# Setup SSH agent with keys
./mctunnel-start.sh --setup-ssh

# Check dependencies
./mctunnel-start.sh --check

# Show help
./mctunnel-start.sh --help
```

### 🔑 SSH Key Management

The script automatically looks for SSH keys in these locations:

- 🔐 `~/.ssh/id_rsa`
- 🔐 `~/.ssh/id_ed25519`
- 🔐 `~/.ssh/crowdstrike_rsa`
- 🦅 `~/.ssh/eagle_rsa`
- 🧙‍♂️ `~/.ssh/merlin_rsa`

For each key found, it will:

1. 🔍 Look for a corresponding passphrase in Bitwarden (named `ssh-<keyname>`)
2. 🔓 Add the key to SSH agent with the passphrase if found
3. 🔑 Add the key without passphrase if no passphrase is found in Bitwarden

### 🗄️ Bitwarden Vault Structure

Store the following items in your Bitwarden vault:

| Item Name | Type | Purpose |
|-----------|------|---------|
| `ssh-id_rsa` | 🔐 Login/Password | Passphrase for ~/.ssh/id_rsa |
| `ssh-eagle_rsa` | 🦅 Login/Password | Passphrase for ~/.ssh/eagle_rsa |
| `ssh-merlin_rsa` | 🧙‍♂️ Login/Password | Passphrase for ~/.ssh/merlin_rsa |

### 🔧 Troubleshooting

1. **🔒 "Bitwarden vault is locked"**:

   ```bash
   export BW_SESSION=$(bw unlock --raw)
   ```

2. **❌ "Not logged into Bitwarden"**:

   ```bash
   bw login
   export BW_SESSION=$(bw unlock --raw)
   ```

3. **⚙️ "mctunnel requires Bash 4.0+"**:
   - The script automatically uses `/opt/homebrew/bin/bash`
   - Install newer bash: `📦 brew install bash`

4. **🔑 SSH key passphrase prompts**:
   - Install expect: `📦 brew install expect`
   - Store passphrases in Bitwarden with correct naming

### 🛡️ Security Notes

- 🔐 SSH key passphrases are retrieved securely from Bitwarden
- 🚫 No passwords are stored in the script or logged
- 🔓 The script requires an active Bitwarden session
- ⏱️ SSH keys are added to the SSH agent for the current session only

### 💡 Examples

```bash
# 🚀 Daily workflow - start tunnels with Bitwarden integration
export BW_SESSION=$(bw unlock --raw)
./mctunnel-start.sh

# 📊 Check if tunnels are running
./mctunnel-start.sh --status

# 🦅 Start only Eagle tunnel
./mctunnel-start.sh eagle

# 🔧 Setup SSH agent without starting tunnels
./mctunnel-start.sh --setup-ssh

# 🧙‍♂️ Start Merlin tunnel only
./mctunnel-start.sh merlin

# ☁️ Start Multicloud tunnel
./mctunnel-start.sh multicloud

# 🔍 Check dependencies and system requirements
./mctunnel-start.sh --check
