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
alias aws_version='~/bin/aws/aws_version.sh'

# Brew
alias bcpa='brew cleanup -s --prune=1'
alias bcu='brew upgrade --cask'
alias bcul='~/bin/mac/bcupg.sh'
alias bpr='brew prune'
alias brewfile='~/bin/mac/brewfile.sh'
alias bup='brew update && brew upgrade'

# DNS
alias freedns='~/bin/mac/freedns.sh'
alias netrestart='~/bin/mac/netrestart.sh'
alias rDNS='~/bin/mac/rDNS.sh'

# Docker
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

# Neofetch
alias fastfetch='fastfetch -c ~/.neofetch.jsonc'

# Getent
alias getent='~/bin/mac/getent.sh'

# GNU Utils
alias ed='ged'

# Git
alias gaa='git add -A'                                    # Add all files
alias gcasm='git commit --amend -S -m'                    # Amend commit with GPG sign
alias gcoall='~/bin/ghe/git_checkout_all.sh'              # Checkout all branches
alias gcpd='~/bin/git/gcpd.sh'                             # Custom git pull diff
alias gcpdm='git checkout main; git pull; git branch -D'  # Checkout main, pull, delete branch (usage: gcpdm <branch>)
alias gcsam='gaa && git commit -S -am'                    # Add all and commit with GPG sign
alias gdb='git diff --name-only --relative --diff-filter=ACDMRTUXB | xargs bat --diff'  # Git diff with bat
alias gg="git log --graph --pretty=format:'%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset' --abbrev-commit --date=relative"  # Pretty git log
alias grpo='git remote prune origin'                      # Prune remote branches
alias gst='git status'                                    # Git status
alias gstb='git stash branch'                             # Stash to new branch
alias gtba='~/bin/git/git_branch_all.sh'                  # Show all branches
alias gurl='git config --get remote.origin.url'           # Get remote URL
alias gwho='~/bin/git/gwho.sh'                            # Custom git who
alias ugit='git-undo'                                     # Undo git command

# Grep
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'

# Hardware
alias hwinfo='~/bin/mac/hwinfo.sh'

# IP Address
alias myip='~/bin/mac/myip.zsh'

# Passgen
alias psg='openssl rand -base64 15'  # Generate random password (20 chars)

# Python
alias mkvenv='python3 -m venv ~/venv'  # Create virtual env in venv
alias venv='source ~/venv/bin/activate'  # Activate virtual env
alias rmvenv='deactivate 2>/dev/null; rm -rf ~/venv'  # Deactivate and remove venv

# Rsync
alias rsync='rsync --progress --stats'

# SSH
alias cmd_broadcast_mac='~/bin/expect/ssh_mac.sh'

# UpdateS
alias ubit='~/bin/git/ubit.sh'
alias ugh='~/bin/git/ugh.sh'
alias ugl='~/bin/git/ugl.sh'
alias umac='~/bin/mac/umac.zsh'
alias unode='~/bin/mac/unode.zsh'
alias unpm='~/bin/mac/unode.zsh'
alias upip='~/bin/mac/upip.zsh'

# Vault
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

# Vim
alias vi='vim'
alias vpi='vim -c "PlugInstall" -c "qa"'
alias vpc='vim -c "PlugClean" -c "qa"'

# Wav2MP3
alias wav2mp3='~/bin/mac/wav2mp3.sh'

# Wget
alias wget='wget -c'

# YouTube DL
alias ytdl='~/bin/mac/ytdl.sh'

# Zoxide
alias zo-clean='~/bin/zoxide/zoxide-clean.sh --pattern'
