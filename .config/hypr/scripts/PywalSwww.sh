#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Pywal Colors for current wallpaper
#
# Was reading swww's, then awww's, cache to figure out the current
# wallpaper. Now on hyprpaper, which callers already know the path for
# (they just set it) -- pass it as $1. Falls back to asking hyprpaper
# directly if called with no argument.

wallpaper_path="$1"

if [ -z "$wallpaper_path" ]; then
    # Best-effort fallback: ask hyprpaper what's currently active and take
    # the first monitor's wallpaper path.
    wallpaper_path=$(hyprctl hyprpaper listactive 2>/dev/null | head -n1 | sed 's/^.*= //')
fi

ln_success=false

if [ -n "$wallpaper_path" ] && [ -f "$wallpaper_path" ]; then
    if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
        ln_success=true
    fi
fi

if [ "$ln_success" = true ]; then
    # execute pywal skipping tty and terminal changes
    wal -i "$wallpaper_path" -s -t &
fi
