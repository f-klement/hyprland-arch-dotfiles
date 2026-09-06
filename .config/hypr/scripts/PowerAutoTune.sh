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

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/PowerModeCommon.sh"

last=""
check_and_apply() {
    local want
    if want_blur_on; then want="on"; else want="off"; fi
    if [ "$want" != "$last" ]; then
        last="$want"
        apply_current
    fi
}

# Correct state immediately on startup, then keep polling. Polling (not an
# upower watch) because this also has to notice the mode file changing from
# a waybar click, not only real AC/battery transitions.
check_and_apply
while true; do
    sleep 3
    check_and_apply
done
