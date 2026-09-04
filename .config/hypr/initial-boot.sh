#!/bin/bash
# A bash script designed to run only once dotfiles installed

# THIS SCRIPT CAN BE DELETED ONCE SUCCESSFULLY BOOTED!! And also, edit ~/.config/hypr/settings.lua
# not necessary to do since this script is only designed to run only once as long as the marker exists
# However, I do highly suggest not to touch it since again, as long as the marker exist, script wont run

# NOTE: this script was missing its `if [ ! -f "$marker" ]; then` guard --
# it only ever had the closing `fi`, which is a bash syntax error that made
# bash refuse to run the ENTIRE script (nothing inside it -- not the GTK
# theme, not the cursor theme, not kvantum -- has ever actually run via this
# file). The .initial_startup_done marker already existed regardless (most
# likely set by hand at some point), so this had gone unnoticed. Guard
# restored below.

marker="$HOME/.config/hypr/.initial_startup_done"

# Variables
scriptsDir=$HOME/.config/hypr/scripts
wallpaper=$HOME/Pictures/wallpapers/Fantasy-Landscape.png
#waybar_style="$HOME/.config/waybar/style/[Pywal] Chroma Tally.css"
kvantum_theme="Tokyo-Night"

#hyprctl hyprpaper wallpaper
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

if [ ! -f "$marker" ]; then

    # Was symlinked to ~/.cache/wal/colors-rofi-dark.rasi (pywal-generated,
    # never actually existed on this system -- dangling symlink, every rofi
    # surface failed to load its theme). Fixed Tokyo Night file instead.
    ln -sf "$HOME/.config/rofi/pywal-color/tokyo-night.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi" > /dev/null 2>&1 &

    # initiate GTK dark mode and apply icon and cursor theme
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme Tokyonight-Dark-BL-LB > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme Tokyonight-Dark > /dev/null 2>&1 &
    # Cursor stays on Dracula-cursors by request (the rest of the desktop
    # converged on Tokyo Night, cursor intentionally didn't). Fixed the
    # missing "s" though -- the installed theme's real name is
    # "Dracula-cursors" (plural); "Dracula-cursor" doesn't exist as an
    # installed theme name, so that lookup would have silently failed too.
    gsettings set org.gnome.desktop.interface cursor-theme Dracula-cursors > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &

    # initiate kvantum theme
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &

    # initiate the kb_layout (for some reason) waybar cant launch it
    "$scriptsDir/SwitchKeyboardLayout.sh" > /dev/null 2>&1 &

    # # Initial waybar style
	# if [ -f "$waybar_style" ]; then
    # 	ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"

	# 	# Refreshing waybar, swaync, rofi etc.
	# 	"$scriptsDir/Refresh.sh" > /dev/null 2>&1 &
	# fi

    # Create a marker file to indicate that the script has been executed.
    touch "$marker"

    exit
fi
