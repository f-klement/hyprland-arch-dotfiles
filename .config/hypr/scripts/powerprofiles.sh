#!/bin/bash
# Power profile switcher menu.
#
# This used to call `powerprofilesctl` (power-profiles-daemon's CLI) via
# `wofi` -- neither is installed on this system. This TUXEDO laptop's power
# management is handled entirely by TUXEDO Control Center's daemon (tccd),
# which talks a completely different D-Bus API
# (com.tuxedocomputers.tccd, not the generic net.hadess.PowerProfiles that
# powerprofilesctl expects) and is already active, already AC/battery-aware
# (see /etc/tcc/settings). Installing power-profiles-daemon on top would be
# redundant with -- and could actively fight -- tccd, so this now talks to
# tccd directly instead. Also switched wofi -> rofi (wofi isn't installed
# either; rofi is what's used everywhere else in this config).

BUS_DEST="com.tuxedocomputers.tccd"
BUS_PATH="/com/tuxedocomputers/tccd"
BUS_IFACE="com.tuxedocomputers.tccd"

# Collect id+name pairs from both the built-in default profiles and any
# custom ones you've made in the TUXEDO Control Center GUI.
profiles_json=$(busctl --system -j call "$BUS_DEST" "$BUS_PATH" "$BUS_IFACE" GetDefaultProfilesJSON 2>/dev/null \
  | jq -r '.data[0]')
custom_json=$(busctl --system -j call "$BUS_DEST" "$BUS_PATH" "$BUS_IFACE" GetCustomProfilesJSON 2>/dev/null \
  | jq -r '.data[0]')

mapfile -t choices < <(
  { echo "$profiles_json"; echo "$custom_json"; } \
    | jq -r 'fromjson? | .[] | "\(.name)\t\(.id)"' 2>/dev/null
)

if [ ${#choices[@]} -eq 0 ]; then
  notify-send -u critical "Power profiles" "Couldn't reach tccd -- is tuxedo-control-center installed and tccd.service running?"
  exit 1
fi

menu_labels=$(printf '%s\n' "${choices[@]}" | cut -f1)
selection=$(printf '%s\n' "$menu_labels" | rofi -dmenu -p "Power profile" -config ~/.config/rofi/config-compact.rasi)

[ -z "$selection" ] && exit 0

for entry in "${choices[@]}"; do
  name="${entry%%$'\t'*}"
  id="${entry##*$'\t'}"
  if [ "$name" = "$selection" ]; then
    busctl --system call "$BUS_DEST" "$BUS_PATH" "$BUS_IFACE" SetTempProfile s "$id" > /dev/null 2>&1
    notify-send -u low "Power profile" "Switched to $name"
    exit 0
  fi
done
