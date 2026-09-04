#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

wallDIR="$HOME/Pictures/wallpapers"
scriptsDir="$HOME/.config/hypr/scripts"

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}


# Transition config
FPS=60
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Was `swww` -- not installed on this system, `awww` is (also no `init`
# subcommand; awww-daemon is its own binary).
awww query > /dev/null 2>&1 || { awww-daemon & disown; sleep 0.3; }
awww img ${RANDOMPICS} $AWWW_PARAMS


${scriptsDir}/PywalSwww.sh
sleep 1
${scriptsDir}/Refresh.sh 

