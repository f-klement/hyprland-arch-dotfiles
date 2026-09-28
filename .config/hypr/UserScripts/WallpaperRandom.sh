#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

wallDIR="$HOME/Pictures/wallpapers"
scriptsDir="$HOME/.config/hypr/scripts"

# Theme-aware (2026-09-16): pick from the active theme's directories --
# wallpaper_dirs=(...) in its theme.sh, the same array DarkLight.sh uses:
# the Dynamic-Wallpapers/Dark or /Light mood dir, plus the curated
# rose-pine/ set for both Rosé Pine themes -- so a light theme doesn't get
# a dark wallpaper every third roll. Falls back to the whole tree when the
# state file / theme dir is missing or the dirs are empty. Applies to
# CTRL+ALT+W, the 30-min WallpaperAutoChange.sh loop and the Quick
# Settings "Random wallpaper" button alike.
wallpaper_base_path="$wallDIR/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
rose_pine_wallpapers="$wallDIR/rose-pine"
wallpaper_dirs=()
theme_sh="$HOME/.config/hypr/themes/$(cat "$HOME/.cache/.theme_mode" 2>/dev/null)/theme.sh"
if [ -f "$theme_sh" ]; then
    # shellcheck source=/dev/null
    . "$theme_sh"
fi
if [ ${#wallpaper_dirs[@]} -eq 0 ]; then
    wallpaper_dirs=("$wallDIR")
fi

PICS=($(find "${wallpaper_dirs[@]}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) 2>/dev/null))
if [ ${#PICS[@]} -eq 0 ]; then
    PICS=($(find "${wallDIR}" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
fi
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

