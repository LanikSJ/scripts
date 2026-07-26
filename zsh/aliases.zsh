# User specific aliases and functions
# OS
alias c='clear'                                                        # Clear terminal screen
alias cls='cd ~/;c'                                                    # Go home and clear screen
alias cp='cp -aR'                                                      # Preserve attributes, recursive copy
alias free='~/bin/mac/memory.sh'                                       # Show memory usage
alias reload='source ~/.zshrc'                                         # Reload zsh configuration

# AWS
if command -v aws >/dev/null 2>&1; then
  alias aup='~/bin/aws/aws_version.sh'                                 # Update AWS CLI version
fi

# Chezmoi
if command -v chezmoi >/dev/null 2>&1; then
  alias cz='chezmoi'                                                   # Manage dotfiles with chezmoi
  compdef cz='chezmoi'
fi

# Brew
if command -v brew >/dev/null 2>&1; then
  alias bcpa='brew cleanup -s --prune=1'                               # Brew cleanup with 1 day prune
  alias bcpall='brew cleanup -s --prune=all'                           # Brew cleanup with all prune
  alias bcu='brew upgrade --cask'                                      # Upgrade all cask apps
  alias bcul='~/bin/mac/bcupg.sh'                                      # Custom brew cask upgrade script
  alias bpr='brew prune'                                               # Remove stale symlinks
  alias brewfile='~/bin/mac/brewfile.sh'                               # Generate Brewfile from installed packages
  alias bup='brew update --auto-update && brew upgrade -y'             # Update brew and upgrade all packages
fi

# Direnv
if command -v direnv >/dev/null 2>&1; then
  alias da='direnv allow'                                              # Allow direnv in current directory
  alias dr='direnv reload'                                             # Reload direnv configuration
fi

# DNS
alias freedns='~/bin/mac/freedns.sh'                                   # Free/clear DNS cache
alias netrestart='~/bin/mac/netrestart.sh'                             # Restart network services
alias rDNS='~/bin/mac/rDNS.sh'                                         # Reverse DNS lookup

# Docker
if command -v docker >/dev/null 2>&1; then
  alias dfimage='~/bin/docker/dfimage.sh'                              # Dockerfile from image analysis
  alias dk='docker'                                                    # Docker shorthand
  alias dkbash='dkelc'                                                 # Alias for docker exec bash into last container
  alias dkcip='docker container prune -f && docker image prune -f'     # Prune containers and images
  alias dkclose='colima stop'                                          # Stop colima VM
  alias dkelc='docker exec -it $(dklcid) bash --login'                 # Exec bash into last created container
  alias dkex='docker exec -it '                                        # Exec interactive command in container (usage: dkex <container> <cmd>)
  alias dki='docker images'                                            # List docker images
  alias dklc='docker ps -l'                                            # Show last created container
  alias dklcid='docker ps -l -q'                                       # Get last created container ID
  alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last container
  alias dkopen='colima start'                                          # Start colima VM
  alias dkps='docker ps'                                               # List running containers
  alias dkpsa='docker ps -a'                                           # List all containers
  alias dkri='docker run --rm -i '                                     # Run container interactively, remove on exit
  alias dkrit='docker run --rm -it '                                   # Run container interactive TTY, remove on exit
  alias dkrmac='docker rm $(docker ps -a -q)'                          # Remove all containers
  alias dkrmflast='docker rm -f $(dklcid)'                             # Force remove last created container
  alias dkrmiall='docker images -a --format "{{.ID}}" | xargs docker rmi -f'  # Force remove all images
  alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'  # Remove dangling images
  alias dl='docker login'                                              # Login to Docker registry

  # Added more recent cleanup options from newer docker versions
  alias dkip='docker image prune -a -f'                                # Prune all unused images
  alias dksp='docker system prune -a -f'                               # Prune entire Docker system
  alias dkspa='docker system prune -af'                                # Prune all, force (alternative syntax)
  alias dkvp='docker volume prune -f'                                  # Prune unused volumes
fi

# Eza — modern ls replacement with colors, icons, and git status
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'                                                       # Colorized directory listing with eza
  alias la='eza -la'                                                   # List all with details
  alias ll='eza -lah'                                                  # List all files with details, human readable sizes
  alias lt='eza --tree'                                                # Tree view
  alias lltr='eza -lah --sort=modified'                                # List all sorted by time, newest on bottom, human readable sizes
  alias lsl='eza -l'                                                   # List with details
  alias lsh='eza -lh'                                                  # List with details, header row
else
  alias ls='ls --color=auto'                                           # Fallback: colorized directory listing
fi

# Fastfetch
if command -v fastfetch >/dev/null 2>&1; then
  alias fastfetch='fastfetch -c ~/.neofetch.jsonc'                     # System info with neofetch config
  alias neofetch='fastfetch'                                           # Map neofetch to fastfetch
fi

# Git
if command -v git >/dev/null 2>&1; then
  alias gaa='git add -A'                                               # Add all files
  alias gcasm='git commit --amend -S -m'                               # Amend commit with GPG sign
  alias gcoall='~/bin/ghe/git_checkout_all.sh'                         # Checkout all branches
  alias gcpd='~/bin/git/gcpd.sh'                                       # Custom git pull diff
  alias gcpdm='git checkout main; git pull; git branch -D'             # Checkout main, pull, delete branch (usage: gcpdm <branch>)
  alias gcsam='git add -A && git commit -S -am'                        # Add all and commit with GPG sign
  alias gdb='git diff --name-only --relative --diff-filter=ACDMRTUXB | xargs bat --diff'  # Git diff with bat
  alias gg="git log --graph --pretty=format:'%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset' --abbrev-commit --date=relative"  # Pretty git log
  alias grpo='git remote prune origin'                                 # Prune remote branches
  alias gst='git status'                                               # Git status
  alias gstb='git stash branch'                                        # Stash to new branch
  alias gtba='~/bin/git/git_branch_all.sh'                             # Show all branches
  alias gtld='git tag -l | xargs git tag -d'                           # Delete local tags
  alias gurl='git config --get remote.origin.url'                      # Get remote URL
  alias gurlw="git remote get-url origin | sed -e 's/:/\//g' -e 's/git@/https:\/\//g' -e 's/\.git$//g'"  # Get remote URL and convert to clickable link
  alias gwho='~/bin/git/gwho.sh'                                       # Custom git who
  alias ugit='git-undo'                                                # Undo last git command
fi

# GitHub CLI
if command -v gh >/dev/null 2>&1; then
  alias ghb='gh browse'                                                # Open current repo in browser (usage: ghb)
  alias ghci='gh run watch'                                            # Watch latest workflow run in terminal
  alias ghco='gh pr checkout'                                          # Checkout a PR locally by number (usage: ghco <pr-number>)
  alias ghcreate='gh repo create'                                      # Create a new GitHub repo (usage: ghcreate <name>)
  alias ghf='gh repo fork'                                             # Fork the current repo to your account
  alias ghis='gh issue list'                                           # List open issues for the current repo
  alias ghme='gh search issues --assignee="@me" --state=open'          # List my open issues across all repos
  alias ghpr='gh pr list'                                              # List open pull requests for the current repo
  alias ghprc='gh pr create'                                           # Create a new pull request from current branch
  alias ghrl='gh release list'                                         # List releases for the current repo
  alias ghst='gh status'                                               # Show gh auth status and config info
  alias ghw='gh repo view --web'                                       # Open the current repo page in default browser
fi

# GNU Utils
if command -v ed >/dev/null 2>&1; then
  alias ed='ged'                                                       # Use GNU ed instead of BSD ed
fi

if command -v egrep >/dev/null 2>&1; then
  alias egrep='egrep --color=auto'                                     # Colorized extended grep
fi

if command -v fgrep >/dev/null 2>&1; then
  alias fgrep='fgrep --color=auto'                                     # Colorized fixed-string grep
fi

alias getent='~/bin/mac/getent.sh'                                     # Get entries from system databases (macOS)
alias grep='grep --color=auto'                                         # Colorized grep

# Hardware
alias hwinfo='~/bin/mac/hwinfo.sh'                                     # Show hardware information

# IP Address
alias myip='~/bin/mac/myip.zsh'                                        # Show public IP address

# Passgen
alias psg='openssl rand -base64 15'                                    # Generate random password (20 chars)

# Python
if command -v python3 >/dev/null 2>&1; then
  alias mkvenv='python3 -m venv ~/venv'                                # Create virtual env in ~/venv
  alias venv='source ~/venv/bin/activate'                              # Activate virtual env
  alias rmvenv='deactivate 2>/dev/null; rm -rf ~/venv'                 # Deactivate and remove venv
fi

# Rsync
alias rsync='rsync --progress --stats'                                 # Verbose rsync with progress

# SSH
alias cmd_broadcast_mac='~/bin/expect/ssh_mac.sh'                      # SSH command broadcast to all Macs

# Terminal utilities
if command -v bat >/dev/null 2>&1; then
  alias cat='bat -p'                                                     # Use bat as a pager with no decorations
fi

if command -v btop >/dev/null 2>&1; then
  alias top='btop'                                                       # System utilization at a glance using btop
fi

if command -v htop >/dev/null 2>&1; then
  alias htop='sudo htop'                                                 # Interactive process viewer as root
fi

if command -v wget2 >/dev/null 2>&1; then
  alias wget='wget2'                                                     # Wget alternative with httpie for better download experience
fi

# Tofu
if command -v tofu >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  alias tofumods='tofu init && jq -r '\''.Modules[].Key'\'' .terraform/modules/modules.json'  # List OpenTofu modules
fi

# Updates
if command -v git >/dev/null 2>&1 && [ -d ~/BitBucket ]; then
  alias ubit='~/bin/git/ubit.sh'                                       # Update all BitBucket repos
fi

if command -v git >/dev/null 2>&1 && [ -d ~/GitHub ]; then
  alias ugh='~/bin/git/ugh.sh'                                         # Update all GitHub repos
fi

if command -v git >/dev/null 2>&1 && [ -d ~/.GitLab ]; then
  alias ugl='~/bin/git/ugl.sh'                                         # Update all GitLab repos
fi

if command -v node >/dev/null 2>&1; then
  alias unode='~/bin/mac/unode.zsh'                                    # Update Node.js
  alias unpm='~/bin/mac/unode.zsh'                                     # Update npm (same script)
fi

if command -v pip >/dev/null 2>&1; then
  alias upip='~/bin/mac/upip.zsh'                                      # Update pip packages
fi

if command -v brew >/dev/null 2>&1; then
  alias umac='~/bin/mac/umac.zsh'                                      # Update macOS packages
fi

# Vault
if command -v vault >/dev/null 2>&1; then
  alias vad='vault delete'                                             # Delete a secret (usage: vad <path>)
  alias vag='vault login -method=okta username=$USER'                  # Vault login via Okta
  alias val='vault list'                                               # List secrets at a path (usage: val <path>)
  alias var='vault read'                                               # Read a secret (usage: var <path>)
  alias vare='vault revoke'                                            # Revoke a secret lease (usage: vare <lease-id>)
  alias varn='vault renew'                                             # Renew a secret lease (usage: varn <lease-id>)
  alias varv='vault read -field=value'                                 # Read a specific field from a secret
  alias vas='vault status'                                             # Show Vault server status
  alias vasrv='vault server'                                           # Start Vault server
  alias vav='vault version'                                            # Show Vault version
  alias vaw='vault write'                                              # Write a secret (usage: vaw <path> <key=value>)
fi

# Vim
if command -v vim >/dev/null 2>&1; then
  alias vi='vim'                                                       # Use vim instead of vi
  alias vpi='vim -c "PlugInstall" -c "qa"'                             # Install vim-plug plugins
  alias vpc='vim -c "PlugClean" -c "qa"'                               # Clean unused vim-plug plugins
  alias vpu='vim -c "PlugUpdate" -c "qa"'                              # Update vim-plug plugins
fi

# Wav2MP3
if command -v ffmpeg >/dev/null 2>&1; then
  alias wav2mp3='~/bin/mac/wav2mp3.sh'                                 # Convert WAV files to MP3
fi

# Wget
if command -v wget >/dev/null 2>&1; then
  alias wget='wget -c'                                                 # Resume interrupted downloads
fi

# YouTube DL
if command -v yt-dlp >/dev/null 2>&1; then
  alias ytdl='~/bin/mac/ytdl.sh'                                       # Download YouTube videos/audio
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  alias zo-clean='~/bin/zoxide/clean.sh --pattern'                     # Clean zoxide DB by pattern
  alias zo-verify='~/bin/zoxide/verify.sh'                             # Verify zoxide DB integrity
  alias zo-cleanup='~/bin/zoxide/cleanup.sh'                           # Clean up stale zoxide entries
fi
