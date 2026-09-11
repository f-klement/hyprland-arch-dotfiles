#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Airplane Mode. Turning on or off all wifi using rfkill. 

notif="$HOME/.config/swaync/images/bell.png"

# Check if any wireless device is blocked
wifi_blocked=$(rfkill list wifi | grep -o "Soft blocked: yes")

if [ -n "$wifi_blocked" ]; then
    rfkill unblock wifi
    notify-send -u low -i "$notif" 'Airplane mode: OFF'
else
    rfkill block wifi
    notify-send -u low -i "$notif" 'Airplane mode: ON'
fi

# Nudge the qemu network watchdog to check immediately (2026-09-11) --
# toggling the physical radio is one of the disturbances that's actually
# broken virbr0/a running VM's interface on this host before. Backgrounded,
# fire-and-forget -- this script's own job (the radio toggle) is already done.
~/.config/hypr/scripts/QemuNetworkWatchdog.sh --once &
disown
