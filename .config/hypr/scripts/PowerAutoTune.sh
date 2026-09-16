#!/bin/bash
## AC/battery-aware blur toggle for Hyprland (2026-09-06, power-draw pass).
## Long-running watcher, started from autostart.lua. Logic lives in
## PowerModeCommon.sh, shared with the waybar power-mode button
## (PowerMode.sh) so both agree on what "auto/performance/powersave" mean.
##
## 60Hz was investigated and ruled out: this panel's EDID/kernel DRM mode
## list has exactly one mode (2880x1800@90, adaptive-sync), confirmed via
## hyprctl, /sys/class/drm and wlr-randr independently. vrr+vfr (both
## already on in settings.lua) are the real equivalent of a refresh-rate
## cut for this specific display.
##
## Event-driven since 2026-09-16: was a 3 s poll (2 cat forks + sleep per
## iteration, ~29k wakeups and ~9 CPU-s a day). Now it blocks on
## `udevadm monitor` for power_supply uevents (AC plug/unplug; works
## unprivileged), with a 5-minute `read -t` timeout as the only fallback
## heartbeat. The poll's other justification -- noticing the mode file
## change from a waybar click -- was moot: PowerMode.sh --cycle/--set and
## the power pane already call apply_current themselves.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/PowerModeCommon.sh"

# Correct state immediately on startup; apply_current is idempotent (a
# single hyprctl eval), so it is simply re-run on every event.
apply_current

while true; do
    # one "UDEV ... change ... (power_supply)" line per event; the plain
    # `read` also wakes on EOF if udevadm ever dies, which restarts it
    udevadm monitor -u -s power_supply 2>/dev/null | while true; do
        if read -t 300 -r line; then
            [[ $line == UDEV* ]] || continue
        elif (( $? <= 128 )); then
            break                       # EOF: udevadm gone
        fi                              # else: 5-min heartbeat
        apply_current
    done
    sleep 5
done
