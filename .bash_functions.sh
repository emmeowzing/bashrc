#! /bin/bash

##
# Get a user's response on a question to set environment variables.
# Call like `X="$(response "Enter your name: " "Brandon")"`
# To set a default value on `X` if the user just hits enter.
response()
{
    if [ $# -eq 0 ]
    then
        _error "Must submit at least 2 arguments to \`response\` function for IO."
        return 1
    elif [ $# -gt 2 ]
    then
        _warning "received >2 arguments at response function, ignoring extra arguments"
    fi

    question="$1"
    default="$2"

    read -r -p "$question" var
    if [ "$var" ]
    then
        printf "%s" "$var"
    else
        if [ "$default" ]
        then
            _warning "Defaulting to $default"
        else
            _warning "Attempted to default, but no value given, returning \"\""
        fi
        printf "%s" "$default"
    fi

    return 0
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
        _error "Expected 1 argument to \`_warning\`, received $#.\\n"
        return 1
    fi

    local message
    message="$1"

    printf "\e[2m\e[1mWARNING\e[0m\e[2m: %s\e[0m\\n" "$message" >&2
}


##
# Drop a .gitignore in my cwd with the most common files I try not to include.
gitignore()
{
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
# Run mypy / type checker before executing a program.
py()
{
    if [ $# -ne 1 ]
    then
        _error "Please provide a Python script."
        return 1
    fi

    local program

    program="$1"

    # Requires shebang line on $program.
    if [ -x "$program" ]
    then
        # Adding flake8 as that's yet another good checker.
        flake8 "$program" # this does not return 0 upon completion :/
        mypy "$program" && "$program"
    else
        printf "Please ensure the Python script is executable.\\n" 1>&2
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
# Export conda environment to current location (so make sure you're in your Git
# repository).
exportConda()
{
    pip freeze > requirements.txt

    return 0
}


##
# If there are no arguments, switch to the next screen in the list.
# shellcheck disable=SC2120
ts()
{
    if [ $# -gt 1 ]
    then
        _error "Only accepts 0 or 1 arguments, received $#"
        return 1
    elif [ $# -eq 1 ]
    then
        tmux switch -t "$1"
    else
        local current next screens

        # No arguments; cycle through the sessions.
        current="$(tmux display-message -p '#S')"
        mapfile -t screens < <(tmux ls | grep -oP "^([^:]+)(?=:)")
        screens=( "${screens[@]}" "${screens[0]}" )
        next=false

        # shellcheck disable=SC2068
        for scrn in ${screens[@]}
        do
            if [ "$scrn" = "$current" ]
            then
                next=true9                continue
            fi
            if $next
            then
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
    if [ $# -gt 1 ]
    then
        _error "Only accepts 0 or 1 arguments, received $#"
        return 1
    elif [ $# -eq 1 ]
    then
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
        
        for ((i=${#screens[@]}-1; i>=0; --i))
        do
            scrn="${screens[i]}"
            if [ "$scrn" = "$current" ]
            then
                former=true
                continue
            fi
            if $former
            then
                tmux switch -t "$scrn"
                return 0
            fi
        done
    fi

    return 0
}


##
# Allocate a raw disk for VMs of some specified size in GiB.
allocate()
{
    if [ $# -ne 2 ]
    then
        _error "** Please provide a disk size (in GiB) and path to file."
        return 1
    fi

    size="$1"
    disk="$2"

    sudo dd if=/dev/zero of="$disk" seek="${size}G" count=0 bs=1
    ll "$disk"

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
    for c in $(docker ps -a | awk '{ print $1 }' | tail -n +2)
    do
        sudo docker rm "$c"
    done

    # Clear images.
    for im in $(docker images | awk '{ print $3 }' | tail -n +2)
    do
        sudo docker rmi "$im"
    done

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
    aws-vault exec "${AWS_PROFILE}" -- command aws "$@"
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