#!/bin/bash

width=-280
state=$(powerprofilesctl get)

    # Provide the user with a GUI menu using wofi
new_state=$(printf "performance\nbalanced\npower-saver" |wofi --dmenu --width=4 -L 5 --style=$HOME/.config/waybar/modules/wofistyle.css --hide-scroll --location 3 --x $width -p "State: $state")
    case $new_state in
        "performance")
            powerprofilesctl set performance
            ;;
        "balanced")
            powerprofilesctl set balanced
            ;;
        "power-saver")
            powerprofilesctl set power-saver
            ;;
             *)
            echo $new_state
            ;;
        esac
    
        echo $new_state