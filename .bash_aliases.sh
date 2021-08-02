# ZFS
alias zl='zfs list -o name,creation,refer,available,mountpoint,mounted,origin'
alias zlt='zfs list -t all -ro name,creation,written,clones'
alias zs='zpool status -vP'
alias zi='zpool iostat -vP'
alias ht='htop'

alias a='zl; zs; zi; va; vmproccount'

# ls
alias lll='ls -las'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Terraform
alias tfswitch='tfswitch -b $HOME/bin/terraform'
alias tf=terraform

# "alert" for long running commands with notify-send.
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Git
alias gi='git init .'
alias ga='git add .'
alias gs='git status'
alias gb='git branch'
alias gc='git commit'
alias gcm='git checkout master'
alias gr='git remote'
alias gl='git log --graph --oneline --all'

# Virsh
alias va='virsh list --all'
alias ve='virsh edit'
alias vb='virsh domblklist --details'

# tmux
alias ta='tmux attach -t'
#alias ts='tmux switch -t'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tmshow="tmux display-message -p '#S'"
alias tn='tmux new -s'
alias td='tmux detach'

# Docker
alias dp='docker ps'
alias dpa='docker ps -a'
alias di='docker images'

# K8s
alias k='kubectl'

# Random utilities
alias lsblkl='lsblk | grep -v loop'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias nmap='nmap --reason'
alias shellcheck='shellcheck -x'
