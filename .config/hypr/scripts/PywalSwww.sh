#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Pywal Colors for current wallpaper

# NOTE: this used to read swww's cache at ~/.cache/swww/<output>, a plain
# file containing just the image path. swww isn't installed on this system
# -- `awww` is, and its cache layout is different: ~/.cache/awww/<version>/
# <output>, and each file's content is "<resize-opts> <image-path>" (space
# separated), not just the bare path.
cache_root="$HOME/.cache/awww"

# Find any per-output cache file under the (version-namespaced) cache dir
cache_file=$(find "$cache_root" -mindepth 2 -maxdepth 2 -type f 2>/dev/null | head -n1)

ln_success=false

if [ -n "$cache_file" ] && [ -f "$cache_file" ]; then
    # Last whitespace-separated field on the line is the image path
    wallpaper_path=$(awk '{print $NF}' "$cache_file")

    if [ -n "$wallpaper_path" ] && ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
        ln_success=true
    fi
fi

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
    # execute pywal
    # wal -i "$wallpaper_path"

    # execute pywal skipping tty and terminal changes
    wal -i "$wallpaper_path" -s -t &
fi
