##
# Drop a .gitignore in my cwd with the most common files I try not to include.
gitignore()
{
    touch .gitignore
    local 
    
    files=(
        ".git/"
        ".env"
        ".idea/"
        ".terraform/"
        "venv/"
    )

    for f in "${files[@]}"
    do
        printf "%s\\n" "$f" >> .gitignore
    done

    return 0
}


##
# Run mypy / type checker before executing a program.
py()
{
    if [ $# -ne 1 ]
    then
        printf "Please provide a Python script.\\n" 1>&2
        return 1
    fi

    local program

    program="$1"

    # Requires shebang line on $program.
    if [ -x "$program" ]
    then
        # EDIT: adding flake8 as that's yet another good checker.
        flake8 "$program" # this does not return 0 upon completion :/
        mypy "$program" && "$program"
    else
        printf "Please ensure the Python script is executable.\\n" 1>&2
    fi
}


##
# Simple wrapper for throwing programs / processes in a screen.
screenb()
{
    if [ $# -ne 2 ]
    then
        printf "\\n\\t** Please provide a name followed by the process string\\n\\n" 1>&2
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
    printf "Ignoring reboot command; please use \`/sbin/reboot\` if you truly wish to do this.\\n" 1>&2

    return 0
}


##
# Export conda environment to current location (so make sure you're in your Git
# repository).
exportConda()
{
    conda env export > environment.yml
    conda list -e > requirements.txt

    return 0
}


##
# If there are no arguments, switch to the next screen in the list.
# shellcheck disable=SC2120
ts()
{
    if [ $# -gt 1 ]
    then
        printf "Only accepts 0 or 1 arguments, received %s\\n" "$#" 1>&2
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
                next=true
                continue
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
        printf "Only accepts 0 or 1 arguments, received %s\\n" "$#" 1>&2
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
        printf "** Please provide a disk size (in GiB) and path to file.\\n" 1>&2
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
        printf "Please provide <user>@<domain> to shut down\\n" 1>&2
        return 1
    fi

    local answer credentials

    credentials="$1"
    read -r -p "Are you sure? (Y/n) " answer

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

    if [ $procs -lt 4 ]
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
        printf "Please provide the container instance ID.\\n" 1>&2
        return 1
    fi

    containerID="$1"

    # Start the shell.
    docker exec -it "$containerID" "$SHELL"

    return 0
}


##
# Kill all "empty" tmux sessions.
tka()
{
    local location="/home/brandon/.tmux/session"

    # shellcheck disable=SC2046
    echo $(tmux display-message -p '#S') > "$location"

    ts

    tk "$(cat "$location")"

    return 0
}


##
# Open a virt-viewer session on any host at home.
vv() {
    if [ $# -ne 2 ]
    then
        printf "Please provide an IP / host name followed by VM name\\n" 1>&2
        return 1
    fi

    host="$1"
    VM="$2"

    virt-viewer -c "qemu+ssh://$host/system" "$VM" &
    disown

    return 0
}
