# User specific aliases and functions
# OS
alias c='clear'
alias cat='bat -p'
alias cls='cd ~/;c'
alias cp='cp -aR'
alias free='~/bin/mac/memory.sh'
alias htop='sudo htop'
alias ll='ls -alh'
alias lltr='ll -tr'
alias ls='ls --color=auto'
alias reload='source ~/.zshrc'

# AWS
if command -v aws >/dev/null 2>&1; then
  alias aup='~/bin/aws/aws_version.sh'
fi

# Brew
if command -v brew >/dev/null 2>&1; then
  alias bcpa='brew cleanup -s --prune=1'
  alias bcpall='brew cleanup -s --prune=all'
  alias bcu='brew upgrade --cask'
  alias bcul='~/bin/mac/bcupg.sh'
  alias bpr='brew prune'
  alias brewfile='~/bin/mac/brewfile.sh'
  alias bup='brew update --auto-update && brew upgrade -y'
fi

# Direnv
if command -v direnv >/dev/null 2>&1; then
  alias da='direnv allow'
  alias dr='direnv reload'
fi

# DNS
alias freedns='~/bin/mac/freedns.sh'
alias netrestart='~/bin/mac/netrestart.sh'
alias rDNS='~/bin/mac/rDNS.sh'

# Docker
if command -v docker >/dev/null 2>&1; then
  alias dfimage='~/bin/docker/dfimage.sh'
  alias dk='docker'
  alias dkbash='dkelc'
  alias dkcip='docker container prune -f && docker image prune -f'
  alias dkclose='colima stop'
  alias dkelc='docker exec -it $(dklcid) bash --login'
  alias dkex='docker exec -it '
  alias dki='docker images'
  alias dklc='docker ps -l'
  alias dklcid='docker ps -l -q'
  alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'
  alias dkopen='colima start'
  alias dkps='docker ps'
  alias dkpsa='docker ps -a'
  alias dkri='docker run --rm -i '
  alias dkrit='docker run --rm -it '
  alias dkrmac='docker rm $(docker ps -a -q)'
  alias dkrmflast='docker rm -f $(dklcid)'
  alias dkrmiall='docker images -a --format "{{.ID}}" | xargs docker rmi -f'
  alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'
  alias dl='docker login'

  # Added more recent cleanup options from newer docker versions
  alias dkip='docker image prune -a -f'
  alias dksp='docker system prune -a -f'
  alias dkspa='docker system prune -af'
  alias dkvp='docker volume prune -f'
fi

# Fastfetch
if command -v fastfetch >/dev/null 2>&1; then
  alias fastfetch='fastfetch -c ~/.neofetch.jsonc'
fi

# Git
if command -v git >/dev/null 2>&1; then
  alias gaa='git add -A'                                    # Add all files
  alias gcasm='git commit --amend -S -m'                    # Amend commit with GPG sign
  alias gcoall='~/bin/ghe/git_checkout_all.sh'              # Checkout all branches
  alias gcpd='~/bin/git/gcpd.sh'                            # Custom git pull diff
  alias gcpdm='git checkout main; git pull; git branch -D'  # Checkout main, pull, delete branch (usage: gcpdm <branch>)
  alias gcsam='git add -A && git commit -S -am'             # Add all and commit with GPG sign
  alias gdb='git diff --name-only --relative --diff-filter=ACDMRTUXB | xargs bat --diff'  # Git diff with bat
  alias gg="git log --graph --pretty=format:'%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset' --abbrev-commit --date=relative"  # Pretty git log
  alias grpo='git remote prune origin'                      # Prune remote branches
  alias gst='git status'                                    # Git status
  alias gstb='git stash branch'                             # Stash to new branch
  alias gtba='~/bin/git/git_branch_all.sh'                  # Show all branches
  alias gurl='git config --get remote.origin.url'           # Get remote URL
  alias gurlw="git remote get-url origin | sed -e 's/:/\//g' -e 's/git@/https:\/\//g' -e 's/\.git$//g'" # Get remote URL and convert to a clickable link
  alias gwho='~/bin/git/gwho.sh'                            # Custom git who
  alias ugit='git-undo'                                     # Undo git command
fi

# GNU Utils
if command -v ed >/dev/null 2>&1; then
  alias ed='ged'
fi

if command -v egrep >/dev/null 2>&1; then
  alias egrep='egrep --color=auto'
fi

if command -v fgrep >/dev/null 2>&1; then
  alias fgrep='fgrep --color=auto'
fi

alias getent='~/bin/mac/getent.sh'
alias grep='grep --color=auto'

# Hardware
alias hwinfo='~/bin/mac/hwinfo.sh'

# IP Address
alias myip='~/bin/mac/myip.zsh'

# Passgen
alias psg='openssl rand -base64 15'  # Generate random password (20 chars)

# Python
if command -v python3 >/dev/null 2>&1; then
  alias mkvenv='python3 -m venv ~/venv'                 # Create virtual env in venv
  alias venv='source ~/venv/bin/activate'               # Activate virtual env
  alias rmvenv='deactivate 2>/dev/null; rm -rf ~/venv'  # Deactivate and remove venv
fi

# Rsync
alias rsync='rsync --progress --stats'

# SSH
alias cmd_broadcast_mac='~/bin/expect/ssh_mac.sh'

# Tofu
if command -v tofu >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  alias tofumods='tofu init && jq -r '\''.Modules[].Key'\'' .terraform/modules/modules.json'
fi

# Updates
if command -v git >/dev/null 2>&1 && [ -d ~/BitBucket ]; then
  alias ubit='~/bin/git/ubit.sh'
fi

if command -v git >/dev/null 2>&1 && [ -d ~/GitHub ]; then
  alias ugh='~/bin/git/ugh.sh'
fi

if command -v git >/dev/null 2>&1 && [ -d ~/.GitLab ]; then
  alias ugl='~/bin/git/ugl.sh'
fi

if command -v node >/dev/null 2>&1; then
  alias unode='~/bin/mac/unode.zsh'
  alias unpm='~/bin/mac/unode.zsh'
fi

if command -v pip >/dev/null 2>&1; then
  alias upip='~/bin/mac/upip.zsh'
fi

if command -v brew >/dev/null 2>&1; then
  alias umac='~/bin/mac/umac.zsh'
fi

# Vault
if command -v vault >/dev/null 2>&1; then
  alias vad='vault delete'
  alias vag='vault login -method=okta username=$USER'
  alias val='vault list'
  alias var='vault read'
  alias vare='vault revoke'
  alias varn='vault renew'
  alias varv='vault read -field=value'
  alias vas='vault status'
  alias vasrv='vault server'
  alias vav='vault version'
  alias vaw='vault write'
fi

# Vim
if command -v vim >/dev/null 2>&1; then
  alias vi='vim'
  alias vpi='vim -c "PlugInstall" -c "qa"'
  alias vpc='vim -c "PlugClean" -c "qa"'
  alias vpu='vim -c "PlugUpdate" -c "qa"'
fi

# Wav2MP3
if command -v ffmpeg >/dev/null 2>&1; then
  alias wav2mp3='~/bin/mac/wav2mp3.sh'
fi

# Wget
if command -v wget >/dev/null 2>&1; then
  alias wget='wget -c'
fi

# YouTube DL
if command -v yt-dlp >/dev/null 2>&1; then
  alias ytdl='~/bin/mac/ytdl.sh'
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  alias zo-clean='~/bin/zoxide/clean.sh --pattern'
  alias zo-verify='~/bin/zoxide/verify.sh'
  alias zo-cleanup='~/bin/zoxide/cleanup.sh'
fi
