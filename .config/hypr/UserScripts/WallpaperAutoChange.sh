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

# NOTE: this whole script was written for `swww`, but that binary doesn't
# exist on this system at all -- what's actually installed is `awww`
# (a separate, CLI-compatible-ish successor project; the daemon is a
# standalone `awww-daemon` binary, not `awww init`). Every `swww img` call
# below has been silently failing with "command not found" this whole
# time, which is why the 30-min wallpaper rotation never visibly did
# anything. Renamed throughout, and the daemon is now started explicitly
# since awww (unlike swww) doesn't auto-spawn it on first use.
awww query > /dev/null 2>&1 || { awww-daemon & disown; sleep 0.3; }

# Edit below to control the images transition
export AWWW_TRANSITION_FPS=60
export AWWW_TRANSITION_TYPE=simple

# This controls (in seconds) when to switch to the next image
INTERVAL=1800

while true; do
	find "$1" \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			awww img "$img"
			$pywal_refresh
			sleep $INTERVAL

		done
done
