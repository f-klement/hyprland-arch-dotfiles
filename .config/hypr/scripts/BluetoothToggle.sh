#!/bin/bash
## Bluetooth radio toggle (waybar's bluetooth module menu -> "Toggle Bluetooth").
##
## BUG FOUND (2026-09-11): this used rfkill block/unblock at first, mirroring
## AirplaneMode.sh's wifi toggle. That's a hardware-level radio kill switch --
## it left BlueZ's adapter in a state waybar's bluetooth module had no format
## defined for (only "format-disabled" and "format-connected" existed, no
## "format-off"/"format-on"/"format-no-controller"), so the module's default
## empty format ("format": "") kicked in and the icon just vanished. With no
## visible icon left to click, getting bluetooth back on meant dropping to a
## terminal. Switched to bluetoothctl's own software power toggle instead,
## which keeps the adapter registered (so waybar's now-defined "format-off"
## state renders correctly, see waybar/modules) and is the same mechanism
## blueman-manager's own power switch uses.

notif="$HOME/.config/swaync/images/bell.png"

if [ "$(bluetoothctl show | grep -oP 'Powered: \K\w+')" = "yes" ]; then
    bluetoothctl power off
    notify-send -u low -i "$notif" 'Bluetooth: OFF'
else
    bluetoothctl power on
    notify-send -u low -i "$notif" 'Bluetooth: ON'
fi
