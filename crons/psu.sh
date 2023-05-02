#! /usr/bin/env bash
# Grep output of pwrstat -status to see if we're on battery. If so, shutdown all VMs gracefully, then shut down the host.


set -eo pipefail
shopt -s nullglob


running_vms()
{
    virsh list | tail -n +3 | head -n -1 | awk '{ print $2 }'
}


if ! pwrstat -status &>/dev/null; then
    printf "pwrstat: permission denied\\n" >&2
    exit 1
fi

if [ "$(pwrstat -status | grep -oP "Utility Power")" != "Utility Power" ]; then
    # Shutdown all running VMs.
    for vm in $(running_vms); do
        virsh shutdown "$vm" | awk NF
    done

    # Make sure every VM is off.
    i=1
    while [ "$i" -le 120 ] && [ "$(running_vms)" != "" ]; do
        sleep 1
        printf "Waiting for VMs to shutdown gracefully... %i / 120 seconds\\n" "$i"
        (( i+=1 ))
    done

    # If there are still VMs, virsh destroy-them. The host matters more at this point.
    for vm in $(running_vms); do
        virsh destroy "$vm" | awk NF
    done

    wall "System is gracefully shutting down due to a power outage onsite."

    shutdown -H 10
fi