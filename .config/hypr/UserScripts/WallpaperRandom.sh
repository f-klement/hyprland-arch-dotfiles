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

# BUG FOUND (2026-09-11): this used to also call Refresh.sh (pkill+relaunch
# waybar/rofi/swaync) after every wallpaper change. That made sense back
# when waybar/rofi actually re-read pywal's wallpaper-derived colors -- but
# they don't anymore (see rofi/pywal-color/tokyo-night.rasi, swaync/style.css:
# both theme identities are static now, not wallpaper-derived), so the
# restart wasn't doing anything for either of them. Its side effect was real
# though: this script runs from WallpaperAutoChange.sh's 30-minute loop, so
# waybar was getting killed and relaunched every 30 minutes -- which
# recreates its idle_inhibitor module from scratch, silently dropping the
# wlr-idle-inhibit hold whenever the "caffeine" toggle had been switched on.
# That's what was making the toggle "turn itself off all the time".
# DarkLight.sh still calls Refresh.sh itself when the identity actually
# changes (style.css's symlink target changes then, so a restart is
# genuinely needed) -- that path is untouched.

