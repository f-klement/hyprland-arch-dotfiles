#!/bin/bash
## Watches libvirt's "default" NAT network (bridge virbr0 by default) and
## repairs it whenever it breaks: the bridge losing its gateway IP while
## libvirt still reports the network as Active, the network being fully
## inactive when it should be running, or a running VM's tap interface
## getting orphaned from the bridge (present, but not enslaved -- link with
## no path out).
##
## WHY THIS EXISTS (2026-09-11): this exact breakage happened live on this
## host after toggling the Wi-Fi radio (wlo1, the host's physical uplink) --
## virbr0 lost its 192.168.122.1/24 address and the running debian-work VM's
## tap disconnected from the bridge, even though `virsh net-info default`
## still reported Active. Confirmed by hand:
##   virsh net-destroy default && virsh net-start default
##   virsh detach-interface <dom> --type network --mac <mac> --live
##   virsh attach-interface <dom> --type network --source default \
##       --mac <mac> --model virtio --live
## This script automates that detect-and-repair sequence continuously, plus
## reacts immediately (not just on the next poll) to the two disturbances
## most likely to cause it: waking from suspend and the Wi-Fi radio
## changing state.
##
## Runs unprivileged: this user is in the `libvirt` group, so `virsh -c
## qemu:///system` talks to libvirtd over its polkit-guarded socket without
## sudo -- same as this script's own repair commands need. Note libvirtd
## itself runs as root and does the actual privileged nft/iptables/bridge
## work when net-start runs, even though this script never touches those
## directly (and can't -- this account has no passwordless sudo, confirmed
## trying to read the nftables ruleset for a NAT-connectivity self-test,
## which is why there isn't one here: a raw `ip link set <iface> master
## <bridge>` was tried first too and needs real root/CAP_NET_ADMIN, which is
## why orphaned-interface repair goes through virsh detach/attach-interface
## instead of re-enslaving the tap directly).
##
## A host-side `ping -I virbr0 <public IP>` self-test was tried as a way to
## catch NAT/firewall breakage specifically (not just bridge-IP loss) but
## dropped: it failed even when the VM demonstrably had a live, current DHCP
## lease and was fine (`virsh net-dhcp-leases default`) -- a host-originated
## ping sourced from the bridge's own gateway address doesn't traverse the
## same path a real VM's forwarded packet does, so it's an unreliable false
## negative here, not a real health signal. If NAT/firewall rules do go bad
## independent of bridge/interface state, this script won't catch it (would
## need root to inspect nftables) -- everything else it catches, it fixes.
##
## Usage:
##   QemuNetworkWatchdog.sh          run forever, polling every $INTERVAL
##   QemuNetworkWatchdog.sh --once   single check-and-repair pass, then exit
## The --once form is for event hooks that want an immediate check instead
## of waiting for the next poll -- see hypr/hypridle.conf's after_sleep_cmd
## (suspend/resume) and hypr/scripts/NetworkMenu.sh (Wi-Fi radio toggle).
## The polling loop stays as the general catch-all for every other
## disturbance (switching networks via nm-applet, DHCP renewal, anything
## not wired to a specific hook) -- matches the existing PowerAutoTune.sh
## poll-loop pattern in this repo. 15s is frequent enough that a VM notices
## within one DHCP retry, infrequent enough to be free.

notif="$HOME/.config/swaync/images/bell.png"
NETWORK="default"
INTERVAL=15

log() { echo "[QemuNetworkWatchdog] $*"; }

virsh_c() { virsh -c qemu:///system "$@" 2>/dev/null; }

net_info_field() {
    # $1 = field label as it appears in `virsh net-info` (e.g. "Active", "Bridge")
    virsh_c net-info "$NETWORK" | awk -F': +' -v f="$1" '$1==f {print $2}'
}

repair_bridge() {
    local bridge active
    bridge=$(net_info_field "Bridge")
    active=$(net_info_field "Active")
    [ -n "$bridge" ] || return 1   # network not defined at all -- nothing to do

    if [ "$active" != "yes" ]; then
        log "network '$NETWORK' is inactive, starting it"
        virsh_c net-start "$NETWORK" >/dev/null
        notify-send -u normal -i "$notif" "QEMU network" "Started libvirt network '$NETWORK' (was inactive)" 2>/dev/null
        sleep 2
        return 0
    fi

    if ! ip -4 -o addr show "$bridge" 2>/dev/null | grep -q .; then
        log "bridge $bridge has no IPv4 address despite network '$NETWORK' being Active -- restarting it"
        virsh_c net-destroy "$NETWORK" >/dev/null
        virsh_c net-start "$NETWORK" >/dev/null
        notify-send -u normal -i "$notif" "QEMU network" "Restarted libvirt network '$NETWORK' -- bridge $bridge had lost its gateway IP" 2>/dev/null
        sleep 2
    fi
}

repair_orphaned_interfaces() {
    local bridge dom
    bridge=$(net_info_field "Bridge")
    [ -n "$bridge" ] || return 0

    while read -r dom; do
        [ -n "$dom" ] || continue
        local iface _type source _model mac
        while read -r iface _type source _model mac; do
            [ "$source" = "$NETWORK" ] || continue
            [ -n "$iface" ] || continue
            # BUG FOUND (2026-09-11), caught within minutes of enabling this:
            # this used to compare `mac` (the domain's guest-side NIC MAC,
            # from domiflist) against the host tap's own link/ether. qemu
            # deliberately gives a network-type tap a DIFFERENT MAC than the
            # guest NIC (first octet 0xfe instead of 0x52, same trailing 5
            # bytes) specifically to avoid an L2 address collision with the
            # guest on the shared bridge -- so that comparison could never
            # match even when everything was healthy, and was detaching and
            # reattaching a perfectly fine interface on every single 15s
            # poll. Caught live in this session's own first run (see git
            # history / conversation for how). Checking the tap interface
            # name (which domiflist already gives directly, no MAC
            # inference needed) for `master $bridge` instead -- domiflist is
            # queried fresh each cycle, so the name is always current, not
            # cached from a previous attach.
            if ! ip link show "$iface" 2>/dev/null | grep -q "master $bridge"; then
                log "$dom's interface $iface ($mac) on '$NETWORK' is orphaned from $bridge -- reattaching"
                virsh_c detach-interface "$dom" --type network --mac "$mac" --live >/dev/null
                sleep 1
                virsh_c attach-interface "$dom" --type network --source "$NETWORK" \
                    --mac "$mac" --model virtio --live >/dev/null
                notify-send -u normal -i "$notif" "QEMU network" "Re-attached ${dom}'s network interface -- it had been orphaned from $bridge" 2>/dev/null
            fi
        done < <(virsh_c domiflist "$dom" | tail -n +3)
    done < <(virsh_c list --name --state-running)
}

check_and_repair() {
    repair_bridge
    repair_orphaned_interfaces
}

if [ "$1" = "--once" ]; then
    check_and_repair
    exit 0
fi

log "starting, polling every ${INTERVAL}s"
while true; do
    check_and_repair
    sleep "$INTERVAL"
done
