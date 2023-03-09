#! /usr/bin/env bash
# Bash aliases and alias-like function shortcuts.

# Not really an alias, but alias-like. Allows you to run `git exec ...some command` at the root of your repo.
git config --global alias.exec '!exec '

alias watch='watch -d '
alias a='zl; zs; zi; va; vmproccount; nvidia-smi; sudo pwrstat -status; atq'
alias c='clear'
alias untar='tar -zxvf'
alias pcau='pre-commit auto-update'
alias dig='dig +noall +answer'
alias ncp='nc -zv'
alias base64='base64 -w0' # Never wrap columns of base64'ed-output.
alias fdisk='sudo fdisk -l | sed -e "/Disk \/dev\/loop/,+5d"'
alias loop='losetup -fvP --show'

##
# Change tabs to spaces on a particular file extension recursively, starting in the current directory.
function tts()
{
    if [ $# -ne 1 ]; then
        _error "Expected at least 1 argument, file extension (e.g. txt, sh, or tf)"
        return 1
    fi

    local ext="$1"

    find . -type f -name "*.$ext" -exec printf "Changing tabs to spaces in %s\\n" {} \; -exec sed -i "s/\t/    /g" {} \;
}

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
alias ga='git add "$(git rev-parse --show-toplevel)"'
alias gs='git status && git diff'
alias gb='git branch'

##
# If .pre-commit-config.yaml exists, pre-commit install.
function gc()
{
    # shellcheck disable=SC2155
    local topLevel="$(git rev-parse --show-toplevel)"

    if [ -f "$topLevel"/.pre-commit-config.yaml ] && { [ ! -f "$topLevel"/.git/hooks/pre-commit ] || [ ! -f "$topLevel"/.git/hooks/prepare-git-msg ]; }; then
        pre-commit install -t pre-commit -t prepare-commit-msg --allow-missing-config -c "$topLevel"/.pre-commit-config.yaml
    fi

    git commit --allow-empty
}

##
# If there is more than one remote, fzf-it-up.
function gp()
{
    if [ "$(git remote | wc -l)" -eq 0 ]; then
        _error "Must set git repository remote"
        return 1
    elif [ "$(git remote | wc -l)" -gt 1  ]; then
        git push -u "$(git remote | fzf)" "$(git branch --show-current)"
    else
        git push -u "$(git remote)" "$(git branch --show-current)"
    fi
}
alias gcp='ga && gc && gp'
alias gcm='git checkout master && git pull'
alias gcd='git checkout develop && git pull'
alias gmm='git merge master'
alias gmd='git merge develop'
alias grm='git rebase master'
alias grd='git rebase develop'
alias gr='git remote -v'
alias gl='git log --graph --oneline --all'

##
# shellcheck disable=SC2120
function gt()
{
    if [ $# -eq 1 ]; then
        VERSION="$1"
        git tag "$VERSION" && git push origin "$VERSION"
    else
        git tag
    fi
}

##
# Pull latest source branch's changes from remote (e.g. develop or master) and merge them into the current branch.
function gpm()
{
    local SOURCE CURRENT
    SOURCE="${1:-develop}"
    CURRENT="$(git branch --show-current)"

    git checkout "$SOURCE" || (git stash drop && git stash && git checkout "$SOURCE") && git pull && git checkout "$CURRENT" && git merge "$SOURCE" && git stash apply
}

##
# Delete git tag locally and remotely.
function gdt()
{
    if [ $# -ne 1 ]; then
        _error "Must supply a tag name"
        return 1
    fi

    local tag="$1"

    git fetch --all --tags

    if ! (gt | grep -iq "$tag"); then
        _error "Tag ${tag} does not exist."
        return 1
    fi

    # Delete the tag locally.
    git tag -d "$tag"

    # Delete the tag on some remote.
    if [ "$(git remote | wc -l)" -eq 0 ]; then
        _error "Must set git repository remote"
        return 1
    elif [ "$(git remote | wc -l)" -gt 1  ]; then
        git push -u "$(git remote | fzf)" --delete "$tag"
    else
        git push -u "$(git remote)" --delete "$tag"
    fi
}

##
# Reset the current git branch against its source branch.
function grb()
{
    if [ $# -ne 1 ]; then
        _error "Function \"grb\" expected one argument: base branch name"
        exit 1
    fi

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    local target_branch="$1"

    git stash drop
    git stash
    git checkout "$target_branch"
    git branch -D "$current_branch"
    git checkout -b "$current_branch"
    git stash apply
}

# Virsh
#alias va='virsh list --all'
function va()
{
    if [ $# -lt 1 ]; then
        virsh list --all
    else
        domain="$1"
        virsh -c qemu+ssh://"$domain"/system list --all
    fi
}
alias ve='virsh edit'
alias vdb='virsh domblklist --details'

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
alias ke='kubectl edit'
alias kd='kubectl drain --ignore-daemonsets'
alias kdebug='kubectl debug -it --image ubuntu:20.04'
alias ctx='kubectl ctx' # krew plugins
alias ns='kubectl ns'
alias kge='kubectl get events --sort-by=".lastTimestamp"'
alias kgp='kubectl get pods -o wide'
alias kgj='kubectl get jobs -o wide'
alias kga='kubectl get all'
alias kgn='kubectl get nodes -o wide'
alias kgns='kubectl get ns'
alias kgdb='kubectl get pod,deploy,rs,sts,ds,svc,ingress,secret | less'
# Get all pods on a particular node in the cluster.
function kgpn()
{
    if [ $# -ne 1 ]; then
        _error "Expected at least 1 argument, cluster node name (k get nodes)"
        return 1
    fi

    local node="$1"

    kubectl get pods -A -o wide --field-selector spec.nodeName="$node"
}

##
# Copy a K8s secret from ns to another.
kcopysecret()
{
    if [ $# -ne 3 ]; then
        _error "Function \"kcopysecret\" expected 3 args: secret name, source ns, dest. ns"
        exit 1
    fi

    local secret_name="$1"
    local source_ns="$2"
    local destination_ns="$3"

    kubectl get secret "$secret_name" --namespace="$source_ns" -o yaml | sed "s/namespace: .*/namespace: ${destination_ns}/" | kubectl apply -f -
}

alias hsr='helm search repo' # <repo> to list chart versions available in a repo
alias hru='helm repo update'
alias hdu='helm dependency update'
alias h='helm'

alias ds='devspace'

alias dockercfg='k create secret generic --type=kubernetes.io/dockercfg --from-file=.dockercfg=$HOME/.docker/config.json dockercfg-secret --dry-run=client -o yaml'
alias dockerconfigjson='k create secret generic --type=kubernetes.io/dockerconfigjson --from-file=.dockerconfigjson=$HOME/.docker/config.json dockercfg-secret --dry-run=client -o yaml'

# Random utilities
alias lsblkl='lsblk -e7'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias nmap='nmap --reason'
alias shellcheck='shellcheck -x'

# AWS CLI
alias aws_rotate='aws-vault rotate --no-session --debug'

# CircleCI
alias cci='circleci'
alias cco='circleci orb'
