#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/bell.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==2{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur:passes 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    pkill hyprpaper
    notify-send -e -u low -i "$notif" "gamemode enabled. All animations off"
    exit
else
	# Was `swww`, then briefly `awww` -- this machine now runs hyprpaper
	# (Hyprland's own wallpaper daemon) instead. No IPC "kill", just the
	# process; it reloads from hyprpaper.conf on restart.
	CURRENT_WALL=$(readlink -f "$HOME/.config/rofi/.current_wallpaper")
	hyprpaper & disown
	sleep 0.3
	hyprctl hyprpaper preload "$CURRENT_WALL" > /dev/null
	hyprctl hyprpaper wallpaper ",$CURRENT_WALL" > /dev/null
	sleep 0.1
	${SCRIPTSDIR}/PywalSwww.sh "$CURRENT_WALL"
	sleep 0.5
	${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" "gamemode disabled. All animations normal"
    exit
fi
hyprctl reload
