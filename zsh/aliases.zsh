# User specific aliases and functions
# OS
alias c='clear'
alias cat="bat -p"
alias cls="cd ~/;c"
alias cp="cp -aR"
alias free="~/bin/mac/memory.sh"
alias htop="sudo htop"
alias reload="source ~/.zshrc"
alias ls="ls --color=auto"
alias ll="ls -alh"
alias lltr="ll -tr"

# AWS
alias aws_version="~/bin/aws/aws_version.sh"

# Brew
alias bcu="brew upgrade --cask"
alias bcul="~/bin/mac/bcupg.sh"
alias bpr="brew prune"
alias brewfile="~/bin/mac/brewfile.sh"
alias bup="brew update && brew upgrade"
alias bcpa="brew cleanup -s --prune=1"

# Code
alias atom="code"

# Crowdstrike
alias mct_add="mctunnel start"
alias mct_del="mctunnel stop"
alias mct_conf="mctunnel config"
alias mct_stat="mctunnel status"

# DNS
alias rDNS="~/bin/mac/rDNS.sh"
alias netrestart="~/bin/mac/netrestart.sh"

# Docker
alias dfimage="~/bin/docker/dfimage.sh"
alias dkcip="docker container prune -f && docker image prune -f"
alias dkopen="open '/Applications/Rancher Desktop.app'"
alias dkrmiall="docker images -a --format "{{.ID}}" |xargs docker rmi -f"
alias dkspa="docker system prune -af"
alias dktags="~/bin/docker/docker-tags.sh"
alias dk='docker'
alias dklc='docker ps -l'  # List last Docker container
alias dklcid='docker ps -l -q'  # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
alias dkps='docker ps'  # List running Docker containers
alias dkpsa='docker ps -a'  # List all Docker containers
alias dki='docker images'  # List Docker images
alias dkrmac='docker rm $(docker ps -a -q)'  # Delete all Docker containers
alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'  # Delete all untagged Docker images
alias dkelc='docker exec -it $(dklcid) bash --login' # Enter last container (works with Docker 1.3 and above)
alias dkrmflast='docker rm -f $(dklcid)'
alias dkbash='dkelc'
alias dkex='docker exec -it ' # Useful to run any commands into container without leaving host
alias dkri='docker run --rm -i '
alias dkrit='docker run --rm -it '

# Added more recent cleanup options from newer docker versions
alias dkip='docker image prune -a -f'
alias dkvp='docker volume prune -f'
alias dksp='docker system prune -a -f'

# Getent
alias getent="~/bin/mac/getent.sh"

# GNU Utils
alias ed="ged"

# Git
alias gcasm='git commit --amend -S -m'
alias gcoall="~/bin/ghe/git_checkout_all.sh"
alias gcpd="~/bin/git/gcpd.sh"
alias gcpdm='git checkout main; git pull; git branch -D'
alias gcsam="git commit -S -am"
alias gg="git log --graph --pretty=format:'%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset' --abbrev-commit --date=relative"
alias grpo="git remote prune origin"
alias gst="git status"
alias gstb="git stash branch"
alias gtba="~/bin/git/git_branch_all.sh"
alias gurl="git config --get remote.origin.url"
alias gwho="~/bin/git/gwho.sh"

# Grep
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

# Hardware
alias hwinfo="~/bin/mac/hwinfo.sh"

# IP Address
alias myip="~/bin/mac/myip.zsh"

# Memory
alias free="~/bin/mac/memory.sh"

# Passgen
alias psg="openssl rand -base64 8 |md5 |head -c8;echo"

# Rsync
alias rsync="rsync --progress --stats"

# SSH
alias cmd_broadcast_mac="~/bin/expect/ssh_mac.sh"
#alias ssh="/usr/bin/ssh"
#alias sshfips="/opt/homebrew/bin/ssh"

# Updates
alias ubit="~/bin/git/ubit.sh"
alias ugh="~/bin/git/ugh.sh"
alias ugl="~/bin/git/ugl.sh"
alias umac="~/bin/mac/umac.zsh"
alias upip="~/bin/mac/upip.zsh"

# Vault
alias vad="vault delete"
alias vag="vault login -method=okta username=$USER"
alias val="vault list"
alias var="vault read"
alias vare="vault revoke"
alias varn="vault renew"
alias varv="vault read -field=value"
alias vasrv="vault server"
alias vas="vault status"
alias vav="vault version"
alias vaw="vault write"

# Vim
alias vi="vim"

# Wget
alias wget="wget -c"

# Youtube DL
alias ytdl="~/bin/mac/ytdl.sh"
