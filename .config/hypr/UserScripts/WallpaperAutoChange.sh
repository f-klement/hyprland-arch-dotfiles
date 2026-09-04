#!/bin/bash
# source https://wiki.archlinux.org/title/Hyprland#Using_a_script_to_change_wallpaper_every_X_minutes

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script uses bash (not POSIX shell) for the RANDOM variable


pywal_refresh=$HOME/.config/hypr/scripts/RefreshNoWaybar.sh

if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# NOTE: this whole script was written for `swww`, then briefly moved to
# `awww` -- neither ended up being the final answer. This machine now runs
# hyprpaper (Hyprland's own official, minimal wallpaper daemon) instead,
# started via exec-once in autostart.lua. hyprpaper has no crossfade/wipe
# transition support (hard cut only) -- that trade-off was made
# deliberately when switching to it.
#
# This controls (in seconds) when to switch to the next image
INTERVAL=1800

while true; do
	find "$1" \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			hyprctl hyprpaper preload "$img" > /dev/null
			hyprctl hyprpaper wallpaper ",$img" > /dev/null
			hyprctl hyprpaper unload all > /dev/null
			$pywal_refresh "$img"
			sleep $INTERVAL

		done
done
