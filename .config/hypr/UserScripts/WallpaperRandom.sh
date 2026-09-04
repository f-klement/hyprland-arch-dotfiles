#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

wallDIR="$HOME/Pictures/wallpapers"
scriptsDir="$HOME/.config/hypr/scripts"

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}


# Was `swww`, then briefly `awww` -- this machine now runs hyprpaper
# (Hyprland's own wallpaper daemon, started via autostart.lua) instead.
# No transition support (hard cut), unlike swww/awww.
hyprctl hyprpaper preload "${RANDOMPICS}" > /dev/null
hyprctl hyprpaper wallpaper ",${RANDOMPICS}" > /dev/null
hyprctl hyprpaper unload all > /dev/null

${scriptsDir}/PywalSwww.sh "${RANDOMPICS}"
sleep 1
${scriptsDir}/Refresh.sh

