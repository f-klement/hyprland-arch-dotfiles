#!/bin/bash
## Waybar power-mode button. `--status` feeds the module's exec (JSON:
## text/tooltip/class); `--cycle` is its on-click, walking
## auto -> performance -> powersave -> auto.
##
## "Performance"/"Power saver" here only force Hyprland's blur -- tccd's own
## AC/battery profile switching (/etc/tcc/settings) is untouched and keeps
## managing CPU/fan/etc regardless of this toggle. For a manual TCC profile
## override, right-click opens the existing powerprofiles.sh rofi menu.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/PowerModeCommon.sh"
notif="$HOME/.config/swaync/images/bell.png"

cycle() {
    local next
    case "$(get_mode)" in
        auto)        next="performance" ;;
        performance) next="powersave" ;;
        *)           next="auto" ;;
    esac
    echo "$next" > "$MODE_FILE"
    apply_current

    case "$next" in
        auto)        notify-send -e -u low -i "$notif" "Power mode: Auto" "Blur follows AC/battery" ;;
        performance) notify-send -e -u low -i "$notif" "Power mode: Performance" "Blur forced on" ;;
        powersave)   notify-send -e -u low -i "$notif" "Power mode: Power saver" "Blur forced off" ;;
    esac

    # Redraw the waybar icon now instead of waiting for its poll interval.
    pkill -RTMIN+8 waybar 2>/dev/null
}

status() {
    local mode icon label
    mode="$(get_mode)"
    case "$mode" in
        performance) icon="󱘖"; label="Performance (blur forced on)" ;;
        powersave)   icon=" "; label="Power saver (blur forced off)" ;;
        *)           icon="↻"
                     if is_on_battery; then label="Auto (on battery, blur off)"; else label="Auto (on AC, blur on)"; fi
                     ;;
    esac
    printf '{"text":"%s","tooltip":"Power mode: %s\\nLeft-click: cycle auto \\u2192 performance \\u2192 power saver\\nRight-click: pick a TCC profile","class":"%s"}\n' \
        "$icon" "$label" "$mode"
}

case "$1" in
    --cycle)  cycle ;;
    --status) status ;;
    *) echo "usage: $(basename "$0") --status|--cycle" >&2; exit 1 ;;
esac
