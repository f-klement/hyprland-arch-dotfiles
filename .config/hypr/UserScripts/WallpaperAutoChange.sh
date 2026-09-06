#!/bin/bash
# source https://wiki.archlinux.org/title/Hyprland#Using_a_script_to_change_wallpaper_every_X_minutes

# This script sits in a loop, picking a new wallpaper at regular intervals.
# Started once from autostart.lua's exec-once block, so its first iteration
# is also what paints the very first wallpaper of the session.
#
# NOTE: this script uses bash (not POSIX shell) for the RANDOM variable

if [[ $# -lt 1 ]] || [[ ! -d $1 ]]; then
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

# BUG FOUND (2026-09-06): this loop used to hand-roll its own
# find/preload/wallpaper/unload/pywal sequence right here, and its `find
# "$1"` had no `-type f` or extension filter -- it walked EVERYTHING under
# the wallpapers directory, including this repo's own .git internals
# (hooks/pre-rebase.sample, COMMIT_EDITMSG, etc.) and subdirectories
# themselves. Whenever the shuffle picked one of those, `hyprctl hyprpaper
# preload` silently failed on the bogus path (leaving no wallpaper drawn
# at all), and the unconditional pywal-refresh call after it still
# symlinked ~/.config/rofi/.current_wallpaper to that same garbage path --
# which is exactly how it ended up pointing at .git/hooks/pre-rebase.sample.
#
# WallpaperSelect.sh's manual picker already had a correctly-extension-
# filtered `find`, and CTRL+ALT+W's WallpaperRandom.sh duplicated that
# filtered logic a second time. Now that this loop just calls
# WallpaperRandom.sh directly, the extension filter (and the
# preload/wallpaper/unload/pywal/refresh sequence) lives in exactly one
# place instead of two out-of-sync copies, and both the initial paint and
# every rotation go through it.
#
# NOTE: WallpaperRandom.sh always reads from its own hardcoded
# $HOME/Pictures/wallpapers, not from $1 -- so as long as this script is
# only ever invoked with that same directory (true today, see
# autostart.lua), nothing changes. Pass a different directory and this
# argument is silently ignored; that coupling would need fixing in
# WallpaperRandom.sh too if that ever stops being true.
scriptDir="$(dirname "${BASH_SOURCE[0]}")"

while true; do
	"${scriptDir}/WallpaperRandom.sh"
	sleep "$INTERVAL"
done
