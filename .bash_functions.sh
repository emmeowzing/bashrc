#! /usr/bin/env bash
# Bash functions.


##
# Reset colors.
reset_colors()
{
    tput sgr0
}


##
# Get a user's response on a question to set environment variables.
# Call like `X="$(response "Enter your name: " "Emma")"`
# To set a default value on `X` if the user just hits enter.
response()
{
    if [ $# -eq 0 ]; then
        _error "Must submit at least 2 arguments to \`response\` function for IO."
        exit 1
    elif [ $# -gt 2 ]; then
        _warning "received >2 arguments at response function, ignoring extra arguments"
    fi

    question="$1"
    default="$2"

    read -r -p "$question (default: \"$default\"): " var
    if [ "$var" ]; then
        printf "%s" "$var"
    else
        if [ "$default" ]; then
            _warning "Defaulting to $default"
        else
            _warning "Attempted to default, but no value given, returning empty \"\""
        fi
        printf "%s" "$default"
    fi
}


##
# Get a user's private response on a question (such as a password) to set environment variables.
response_private()
{
    if [ $# -eq 0 ]; then
        _error "Must submit at least 1 arguments to response_private function for IO."
        exit 1
    elif [ $# -gt 1 ]; then
        _warning "received >1 arguments at response_private function, ignoring extra arguments"
    fi

    question="$1"

    while true; do
        read -r -s -p "${question}: " var
        if [ "$var" ]; then
            printf "%s" "$var"
            break
        else
            _error "Field cannot be blank."
        fi
    done
}


##
# Get a user's yes or no response on a question.
response_yn()
{
    if [ $# -eq 0 ]; then
        _error "Must submit at least 1 arguments to response_yn function for IO."
        exit 1
    elif [ $# -gt 1 ]; then
        _warning "received >1 arguments at response_yn function, ignoring extra arguments"
    fi

    question="$1"

    while true; do
        read -r -p "${question} (yes/no): " var

        if [ -z "$var" ]; then
            _error "Must pick one (yes/no)"
            continue
        fi

        if [[ "$var" =~ ^[Yy].*$ ]]; then
            return 0
        fi

        return 1
    done
}


##
# Print an error message to stderr.
_error()
{
    if [ $# -ne 1 ]
    then
        printf "Expected 1 argument to \`_error\`, received %s.\\n" "$#" >&2
        exit 1
    fi

    local message
    message="$1"

    printf "\e[2m\e[1mERROR\e[0m\e[2m: %s\e[0m\\n" "$message" >&2
}


##
# Print a warning message to stderr.
_warning()
{
    if [ $# -ne 1 ]
    then
        _error "Expected 1 argument to \`_warning\`, received $#."
        exit 1
    fi

    local message
    message="$1"

    printf "\e[2m\e[1mWARNING\e[0m\e[2m: %s\e[0m\\n" "$message" >&2
}


##
# Print an informational message to stdout.
_info()
{
    if [ $# -ne 1 ]; then
        _error "Expected 1 argument to \`_info\`, received $#." >&2
        exit 1
    fi

    local message
    message="$1"

    printf "\e[1mINFO:\e[0m %s\\n" "$message"
}


##
# Check for required commands to run this script (prerequisites).
dependencies()
{
    declare -A commands
    local commands=(
        [docker]="Must install Docker (https://docs.docker.com/engine/install/)"
        [mapfile]="Upgrade bash version (brew install bash)"
    )

    for comm in "${!commands[@]}"; do
        if ! command -v "$comm" >/dev/null; then
            _error "Command \"$comm\" not found. (To install: ${commands[$comm]})"
        fi
    done
}


##
# Drop a .gitignore in my cwd with the most common files I try not to include.
gitignore()
{
    if [ $# -eq 0 ]; then
        _warning "Didn't receive any arguments, creating empty .gitignore"
        touch .gitignore
        return 0
    fi

    # https://stackoverflow.com/a/17841619/3928184
    _join_by() {
        local d=${1-} f=${2-}
        if shift 2; then
            printf %s "$f" "${@/#/$d}"
        fi
    }

    curl -ssL "https://www.toptal.com/developers/gitignore/api/$(_join_by "," "$@")" > .gitignore

    return 0
}


##
# Dump my typical default pre-commit config in the current directory.
precommit()
{
    cat << PRECOMMIT > .pre-commit-config.yaml
fail_fast: true
repos:
  - repo: https://github.com/emmeowzing/pre-commit-gitlabci-lint
    rev: v1.1.5
    hooks:
      - id: gitlabci-lint
        # Expects env var like GITHUB_TOKEN=\"\$\(pass show github-token\)\".
        args:
          [
            -b, 'https://git.ops.sbe-vision.com',
            -c, .gitlab-ci.yml
          ]

  # Requires hadolint binary on local machine.
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
        args:
          - --config
          - .hadolint.yaml
          - Dockerfile

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: check-added-large-files
        args: [--maxkb=10000, --enforce-all]
      - id: check-executables-have-shebangs
      - id: check-shebang-scripts-are-executable
      - id: mixed-line-ending

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v0.991
    hooks:
      - id: mypy
        args:
          - --install-types
          - --non-interactive
          - --config-file=.mypy.ini

  # - repo: https://github.com/mgedmin/check-manifest
  #   rev: "0.48"
  #   hooks:
  #     - id: check-manifest
  #       args:
  #        - --ignore
  #        - "*.json,*.txt,*.yaml,.mypy.ini,config/*.md,docker/*.sh,,examples/*,helm/*,package/*,scripts/*,service/*,tests/*,.circleci/*,.pylintrc,.tool-versions,docker/**/*,helm/**/*,examples/**/*"

  - repo: https://github.com/jumanjihouse/pre-commit-hooks
    rev: 3.0.0
    hooks:
      - id: shellcheck
        args:
          - -x

  - repo: https://github.com/emmeowzing/dynamic-continuation-orb
    rev: v3.6.8
    hooks:
      - id: circleci-config-validate

  - repo: https://github.com/emmeowzing/circleci-orb-pre-commit-hook
    rev: v1.3.2
    hooks:
    - id: circleci-orb-validate

  # - repo: https://github.com/k-ogawa-1988/yamale-pre-commit
  #   rev: v0.0.2
  #   hooks:
  #     - id: yamale-validate
  #       args:
  #         - conf/schema.yaml

  - repo: https://github.com/gruntwork-io/pre-commit
    rev: v0.1.17
    hooks:
      - id: helmlint

  - repo: https://github.com/python-poetry/poetry
    rev: 1.3.0
    hooks:
      - id: poetry-check
      - id: poetry-lock
      - id: poetry-export
        args: ["-f", "requirements.txt", "-o", "requirements.txt"]

  - repo: https://github.com/PyCQA/pylint
    rev: v2.16.0b1
    hooks:
      - id: pylint
        args:
          - --rcfile=.pylintrc
          - premiscale/

  - repo: https://github.com/abravalheri/validate-pyproject
    rev: v0.12.1
    hooks:
      - id: validate-pyproject

  # - repo: https://github.com/charliermarsh/ruff-pre-commit
  #   rev: v0.0.237
  #   hooks:
  #     - id: ruff
  #       args: [--fix]
  #       exclude: ^resources

  - repo: https://github.com/premiscale/pre-commit-hooks
    rev: v0.0.7
    hooks:
    -   id: msg-issue-prefix

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.2
    hooks:
     - id: terraform_fmt
       args:
         - --args=-no-color
         - --args=-diff
         - --args=-write=false
PRECOMMIT

    pre-commit autoupdate
}


##
# Drop a default .circleci/config.yml structure with setup workflows enabled.
circle()
{
    if [ ! -d .circleci/ ]; then
        mkdir .circleci
    fi

    if [ ! -f .circleci/config.yml ]; then
        cat > .circleci/config.yml << CIRCLE
version: 2.1

setup: true


executors: {}


orbs: {}


commands: {}


jobs: {}


workflows: {}
CIRCLE
    fi

    return 0
}


##
# Simple wrapper for throwing programs / processes in a screen.
screenb()
{
    if [ $# -ne 2 ]
    then
        _error "** Please provide a name followed by the process string."
        return 1
    fi

    local screenName processString

    screenName="$1"
    processString="$2"

    # Start screen with logging
    screen -L -Logfile "/fastAccessPool/logging/screens/${screenName}_$(date +%H-%M-%S-%F)" -DmS "$screenName" /bin/bash -c "$processString" &

    return 0
}


##
# Alias the `reboot` command and require a user to use the full `/sbin/reboot`
# in order to do so. I've done this before, and it messes up my VMs if they're
# running and not saved.
reboot()
{
    _warning "Ignoring reboot command; please use \`/sbin/reboot\` if you truly wish to do this."

    return 1
}


##
# Allocate a raw disk for VMs of some specified size in GiB.
allocate()
{
    if [ $# -ne 2 ]; then
        _error "** Please provide a disk size (in GiB) and path to file."
        return 1
    fi

    local size disk

    size="$1"
    disk="$2"

    sudo dd if=/dev/zero of="$disk" seek="${size}G" count=0 bs=1
    ll "$disk"

    return 0
}


##
# Resize VM disk images by some amount in GiB.
resize()
{
    if [ $# -ne 2 ]; then
        _error "** Please provide a disk size modifier (in GiB, e.g., \"+10G\" or \"-10G\") and path to file."
        return 1
    fi

    local size disk modifier format

    size="$1"
    disk="$2"
    modifier="${disk:0:1}"
    format="${disk##*.}"

    if [ "$modifier" != "-" ] && [ "$modifier" != "+" ]; then
        _error "** Disk size must include prefix modifier +/-."
        return 1
    fi

    if [ "$modifier" = "-" ]; then
        qemu-img resize "$disk" -f "$format" --shrink "$size"
    else
        qemu-img resize "$disk" -f "$format" "$size"
    fi

    return 0
}


##
# Switch rancher cluster contexts.
rancher_cluster()
{
    if [ $# -ne 1 ]; then
        _error "** Please provide a cluster name."
        return 1
    fi

    local cluster="$1"

    if [ ! -d "$HOME/.kube" ]; then
        mkdir "$HOME/.kube"
    fi

    rancher clusters kf "$cluster" > "$HOME/.kube/config"
    export KUBECONFIG="$HOME"/.kube/config

    return 0
}


##
# Reboot a remote system (gracefully).
rbr()
{
    if [ $# -ne 1 ]
    then
        _error "Please provide <user>@<domain> to shut down."
        return 1
    fi

    local answer credentials

    credentials="$1"
    read -r -p "Are you sure? (Y/n) " answer

    sleep 2

    if [[ "$answer" =~ ^[yY].* ]]
    then
        ssh -t "$credentials" "sudo reboot now"
    else
        printf "Aborting\\n"
    fi

    return 0
}


##
# Get total number of processors in use by running VMs.
vmproccount()
{
    local domains domain cpuSum cpus asDomains procs hostSafe

    cpuSum=0
    procs=$(nproc)
    domains=$(virsh list --name)

    if [ "$procs" -lt 4 ]
    then
        hostSafe=$(( procs / 2 ))
    else
        hostSafe=4
    fi

    printf "\\n\033[1m\033[92mAvailable Processors: %s\033[0m\\n\\n" "$(nproc)"

    declare -A asDomains
    asDomains=()

    # Gather all CPU counts for a nice presentation.
    # shellcheck disable=SC2068
    for domain in ${domains[@]}
    do
        cpus=$(virsh dominfo "$domain" | grep -oP "CPU\(s\):[^0-9]+\K[0-9]+")
        (( cpuSum += cpus ))
        asDomains["$domain"]="$cpus"
    done

    # Now print the collection.
    # shellcheck disable=SC2068
    for domain in ${!asDomains[@]}
    do
        printf "%s: %d\\n" "$domain" "${asDomains[$domain]}"
    done | column -t

    if [ $cpuSum -lt $(( procs - hostSafe )) ]
    then
        # Green
        printf "\\n\033[1m\033[92mTotal: %d\033[0m\\n\\n" "$cpuSum"
    else
        # Red
        printf "\\n\033[1m\033[91mTotal: %d\033[0m\\n\\n" "$cpuSum"
    fi

    return 0
}


##
# Initialize a directory path with base Terraform module files.
tfinit()
{
    if [ $# -ne 1 ]
    then
        _error "Please provide a path to the module's directory."
        return 1
    fi

    local path="$1" fs f

    fs=(
        inputs.tf
        outputs.tf
        main.tf
        terraform.tf
    )

    for f in "${fs[@]}"; do
        touch "$path"/"$f"

        if [ "$f" = "terraform.tf" ]; then
            cat << EOF >> "$path"/"$f"
terraform {
  required_providers {

  }

  required_version = "~> 1.3.6"
}
EOF
        fi
    done
}


##
# Start a shell in a running Docker container.
dockbasher()
{
    local containerID

    if [ $# -ne 1 ]
    then
        _error "Please provide the container instance ID."
        return 1
    fi

    containerID="$1"

    # Start the shell.
    docker exec -it "$containerID" "$SHELL"

    return 0
}


##
# Clear all containers and unused images. Useful after you've just tested a Dockerfile build a bunch of times.
clear_containers()
{
    # Clear containers.
    for c in $(sudo docker ps -a | awk '{ print $1 }' | tail -n +2)
    do
        sudo docker rm "$c"
    done

    # Clear images.
    for im in $(sudo docker images | awk '{ print $3 }' | tail -n +2)
    do
        sudo docker rmi "$im"
    done

    return 0
}


##
# Authenticate to GCR with Docker.
gauth_docker()
{
    gcloud auth login
    gcloud auth configure-docker

    return 0
}


##
# Open a virt-viewer session on any host at home.
vv()
{
    if [ $# -ne 2 ]
    then
        _error "Please provide an IP / host name followed by VM name."
        return 1
    fi

    host="$1"
    VM="$2"

    virt-viewer -c "qemu+ssh://$host/system" "$VM" &
    disown

    return 0
}


##
# AWS helper commands
aws()
{
    aws-vault exec "${AWS_PROFILE}" -- aws "$@"
}

aws-rotate()
{
    aws-vault rotate "$1"
}

aws-login()
{
    aws-vault login "$1"
}

tf()
{
    aws-vault exec "${AWS_PROFILE}" -- terraform "$@"
}


##
# Query the local arp cache for IPs and return them, sorted.
subnetIPs()
{
    arp -n | tail -n +2 | sort -t . -k 1,1n -k 2,2n -k 2,2n -k 3,3n -k 4,4n | awk '{ print $1 }'
}


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