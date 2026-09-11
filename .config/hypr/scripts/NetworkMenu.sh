#!/bin/bash
## Network menu (waybar's "network" module, left-click).
##
## Replaces two earlier attempts (2026-09-11): first a bare-click radio
## toggle (disabled Wi-Fi with a single stray click, no confirmation), then
## a right-click-opens-nm-connection-editor "fix" for that -- but
## nm-connection-editor is a connection-profile editor, not a live network
## picker, so it had nothing useful for the everyday case (switch SSID,
## check signal, reconnect). This is what nm-applet's own left-click menu
## used to provide, rebuilt here as a rofi menu: live SSID list with
## signal/security, one click to (re)connect, a toggle, and the profile
## editor still available as the last resort for real configuration.
##
## Toggle uses `nmcli radio wifi`, NOT rfkill -- rfkill operates below
## NetworkManager and can leave NM's own state out of sync with it, which is
## what made the earlier rfkill-based toggle (AirplaneMode.sh, reused here
## at first) fail to reliably reconnect on re-enable. nmcli goes through
## NetworkManager's own API, so re-enabling reliably triggers its normal
## autoconnect/reassociate path.
##
## Plain text labels throughout, deliberately no icons here -- this repo has
## a proven history in this exact task of guessing Nerd Font codepoints
## wrong (see waybar/modules bluetooth/network blocks); rofi entries don't
## need an icon the way a bar module does, so it's not worth the risk.

rofi_config="$HOME/.config/rofi/config-compact.rasi"
notif="$HOME/.config/swaync/images/bell.png"

wifi_state=$(nmcli radio wifi)
current_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2}')

if [ "$wifi_state" = "enabled" ]; then
    status="Wi-Fi is on$( [ -n "$current_ssid" ] && echo " -- connected to $current_ssid" || echo " -- not connected" )"
else
    status="Wi-Fi is off"
fi

build_menu() {
    if [ "$wifi_state" = "enabled" ]; then
        echo "Turn Wi-Fi off"
        # IN-USE,SSID,SIGNAL,SECURITY -- de-duplicated by SSID (an AP can
        # show up once per band/BSSID), active connection marked.
        nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null \
            | awk -F: '$2 != "" && !seen[$2]++ {
                  mark = ($1 == "*") ? "* " : "  ";
                  lock = ($4 == "") ? "" : "  [locked]";
                  printf "%s%s (%s%%)%s\n", mark, $2, $3, lock
              }'
    else
        echo "Turn Wi-Fi on"
    fi
    echo "Connection Editor..."
}

choice=$(build_menu | rofi -dmenu -p "Network" -mesg "$status" -config "$rofi_config")

[ -n "$choice" ] || exit 0

case "$choice" in
    "Turn Wi-Fi off")
        nmcli radio wifi off
        notify-send -u low -i "$notif" 'Wi-Fi: OFF'
        ;;
    "Turn Wi-Fi on")
        nmcli radio wifi on
        notify-send -u low -i "$notif" 'Wi-Fi: ON'
        ;;
    "Connection Editor...")
        nm-connection-editor &
        disown
        ;;
    *)
        ssid=$(sed -E 's/^[* ] //; s/ \([0-9]+%\)(  \[locked\])?$//' <<< "$choice")
        locked=$(grep -q '\[locked\]$' <<< "$choice" && echo yes || echo no)

        if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
            # Already have a saved profile for it -- just activate that.
            if nmcli connection up id "$ssid" >/dev/null 2>&1; then
                notify-send -u low -i "$notif" "Connected to $ssid"
            else
                notify-send -u normal -i "$notif" "Failed to connect to $ssid"
            fi
        elif [ "$locked" = "yes" ]; then
            pw=$(rofi -dmenu -password -p "Password for $ssid" -config "$rofi_config")
            if [ -n "$pw" ]; then
                if nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
                    notify-send -u low -i "$notif" "Connected to $ssid"
                else
                    notify-send -u normal -i "$notif" "Failed to connect to $ssid (wrong password?)"
                fi
            fi
        else
            if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
                notify-send -u low -i "$notif" "Connected to $ssid"
            else
                notify-send -u normal -i "$notif" "Failed to connect to $ssid"
            fi
        fi
        ;;
esac
