#!/bin/bash
## Shared by PowerAutoTune.sh (the background AC/battery watcher) and
## PowerMode.sh (the waybar power-mode button). Source, don't execute.
##
## Scope is deliberately just Hyprland's blur -- tccd already switches its
## own power profile natively on AC/battery (/etc/tcc/settings,
## stateMap.power_ac/power_bat), so this doesn't touch that at all. Forcing
## a specific TCC profile by hand is still ~/.config/hypr/scripts/powerprofiles.sh's job.

MODE_FILE="$HOME/.cache/.power_mode"   # auto | performance | powersave

apply_blur_on() {
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 1, new_optimizations = true, xray = true } } })' >/dev/null 2>&1
}

apply_blur_off() {
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })' >/dev/null 2>&1
}

is_on_battery() {
    [ "$(cat /sys/class/power_supply/AC0/online 2>/dev/null)" = "0" ]
}

get_mode() {
    case "$(cat "$MODE_FILE" 2>/dev/null)" in
        performance) echo "performance" ;;
        powersave)   echo "powersave" ;;
        *)           echo "auto" ;;
    esac
}

want_blur_on() {
    case "$(get_mode)" in
        performance) return 0 ;;
        powersave)   return 1 ;;
        *)           ! is_on_battery ;;
    esac
}

apply_current() {
    if want_blur_on; then apply_blur_on; else apply_blur_off; fi
}
