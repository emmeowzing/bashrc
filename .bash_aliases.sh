#! /bin/bash

alias watch='watch '
alias a='zl; zs; zi; va; vmproccount; nvidia-smi; sudo pwrstat -status'
alias c='clear'
alias untar='tar -zxvf'

# Jump Down
alias 1d='cd ..'
alias 2d='1d && 1d'
alias 3d='1d && 2d'
alias 4d='1d && 3d'
alias 5d='1d && 4d'

# ZFS
alias zl='zfs list -o name,creation,refer,available,mountpoint,mounted,origin'
alias zlt='zfs list -t all -ro name,creation,written,clones'
alias zs='zpool status -vP'
alias zi='zpool iostat -vP'
alias htop='htop --tree'
alias ht='htop'

# ls
alias lll='ls -lash'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Terraform
alias tfswitch='tfswitch -b $HOME/bin/terraform'
alias tf=terraform

# "alert" for long running commands with notify-send.
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Git
alias g='git'
alias gi='git init .'
alias ga='git add .'
alias gs='git status && git diff'
alias gb='git branch'
alias gc='git commit'
alias gp='git push'
alias gcp='git add . && git commit && git push'
alias gcm='git checkout master'
alias gcd='git checkout develop'
alias gmm='git merge master'
alias gmd='git merge develop'
alias gr='git remote -v'
alias gl='git log --graph --oneline --all'
alias gt='git tag'

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
alias ds='devspace'
alias ctx='kubectl ctx' # krew plugins
alias ns='kubectl ns'
alias helmsearch='helm search repo' # <repo> to list chart versions available in a repo
alias hru='helm repo update'
alias hdu='helm dependency update'
alias h='helm'

# Random utilities
alias lsblkl='lsblk | grep -v loop'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias nmap='nmap --reason'
alias shellcheck='shellcheck -x'

# AWS CLI
alias aws_rotate='aws-vault rotate --no-session --debug'

# CircleCI
alias cci='circleci'
alias cco='circleci orb'
