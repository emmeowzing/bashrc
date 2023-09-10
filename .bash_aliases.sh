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
alias code.='code .'

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
alias gs='git status && git diff'
alias ga='git add "$(git rev-parse --show-toplevel)"'

##
# Fuzzyfind git branch
function gb()
{
    git pull --all && git fetch --all >/dev/null

    branch="$(git branch -r | fzf | xargs)"

    # TODO: Handle the multiple-remote case.
    for remote in $(git remote); do
        if [[ "$branch" =~ ^"$remote" ]]; then
            git checkout -b "$(printf "%s" "$branch" | grep -oP "(?<=\/).*")" "$branch"
            return 0
        fi
    done

    git checkout "$branch"
}


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
# alias gcm='git checkout master && git pull'

##
# Git checkout master or main.
function gcm()
{
    if [ "$(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -P "^(master)$")" = "main" ]; then
        git checkout main && git pull
    elif [ "$(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -P "^(master)$")" = "master" ]; then
        git checkout master && git pull
    else
        _error "neither branches \"main\" nor \"master\" exist on this project."
    fi
}

alias gcd='git checkout develop && git pull'
alias gmm='git merge master'
alias gmd='git merge develop'
alias grm='git rebase master'
alias grd='git rebase develop'
alias gr='git remote -v'
alias gl='git log --graph --oneline --all'
alias glabclone='glab repo clone --group sbevision --paginate --include-subgroups'

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
        return 1
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


##
# If there are no arguments, switch to the next screen in the list.
# shellcheck disable=SC2120
ts()
{
    if [ $# -gt 1 ]; then
        _error "Only accepts 0 or 1 arguments, received $#"
        return 1
    elif [ $# -eq 1 ]; then
        tmux switch -t "$1"
    else
        local current next screens

        # No arguments; cycle through the sessions.
        current="$(tmux display-message -p '#S')"
        mapfile -t screens < <(tmux ls | grep -oP "^([^:]+)(?=:)")
        screens=( "${screens[@]}" "${screens[0]}" )
        next=false

        # shellcheck disable=SC2068
        for scrn in ${screens[@]}; do
            if [ "$scrn" = "$current" ]; then
                next=true
                continue
            fi

            if $next; then
                tmux switch -t "$scrn"
                return 0
            fi
        done

        return 0
    fi
}


##
# Same as `ts`, but in the opposite direction (so you don't have to cycle
# back around to get back to the former screen). This is pretty much the same
# exact function body, just backward loop.
st()
{
    if [ $# -gt 1 ]; then
        _error "Only accepts 0 or 1 arguments, received $#"
        return 1
    elif [ $# -eq 1 ]; then
        # Either ts or st may be used to switch to a specific screen name.
        tmux switch -t "$1"
    else
        local current screens former

        # No arguments; cycle through the sessions.
        current="$(tmux display-message -p '#S')"
        mapfile -t screens < <(tmux ls | grep -oP "^([^:]+)(?=:)")
        #mapfile -t screens < <(echo ${screens[-1]} && echo ${screens[@]})
        # shellcheck disable=SC2206
        screens=( ${screens[-1]} ${screens[@]} )
        former=false

        for ((i=${#screens[@]}-1; i>=0; --i)); do
            scrn="${screens[i]}"
            if [ "$scrn" = "$current" ]; then
                former=true
                continue
            fi

            if $former; then
                tmux switch -t "$scrn"
                return 0
            fi
        done
    fi

    return 0
}


# Docker
alias dp='docker ps'
alias dpa='docker ps -a'
alias di='docker images'

# K8s
alias k='kubectl'
alias ke='kubectl edit'
alias kg='kubectl get'
alias kd='kubectl drain --ignore-daemonsets'
alias kdebug='kubectl debug -it --image ubuntu:20.04'
alias ctx='kubectl ctx' # krew plugins
alias ns='kubectl ns'
alias kge='kubectl get events --sort-by=".lastTimestamp"'
alias kgp='kubectl get pods -o wide'
alias kgj='kubectl get jobs -o wide'
alias kgi='kubectl get ingress'
alias kgd='kubectl get deploy'
alias kga='kubectl get all'
alias kgs='kubectl get secret'
alias kgn='kubectl get nodes -o wide'
alias kgns='kubectl get ns'
alias kgdb='kubectl get pod,deploy,rs,sts,ds,svc,ingress,secret | less'


# ##
# # Clean a newly-generated Helm
# function


##
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
        return 1
    fi

    local secret_name="$1"
    local source_ns="$2"
    local destination_ns="$3"

    kubectl get secret "$secret_name" --namespace="$source_ns" -o yaml | sed "s/namespace: .*/namespace: ${destination_ns}/" | kubectl apply -f -
}

alias hsr='helm search repo' # <repo> to list chart versions available in a repo
alias hrl='helm repo list'
alias hru='helm repo update'
alias hsu='helm search repo'
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
