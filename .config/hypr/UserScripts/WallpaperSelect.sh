#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This script for selecting wallpapers (SUPER W)

SCRIPTSDIR="$HOME/.config/hypr/scripts"

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"

# Check if swaybg is running
if pidof swaybg > /dev/null; then
  pkill swaybg
fi

set_wallpaper() {
  hyprctl hyprpaper preload "$1" > /dev/null
  hyprctl hyprpaper wallpaper ",$1" > /dev/null
  hyprctl hyprpaper unload all > /dev/null
}

# Retrieve image files
PICS=($(ls "${wallDIR}" | grep -E ".jpg$|.jpeg$|.png$|.gif$"))
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command
rofi_command="rofi -show -dmenu -config ~/.config/rofi/config-wallpaper.rasi"

menu() {
  for i in "${!PICS[@]}"; do
    # Displaying .gif to indicate animated images
    if [[ -z $(echo "${PICS[$i]}" | grep .gif$) ]]; then
      printf "$(echo "${PICS[$i]}" | cut -d. -f1)\x00icon\x1f${wallDIR}/${PICS[$i]}\n"
    else
      printf "${PICS[$i]}\n"
    fi
  done

  printf "$RANDOM_PIC_NAME\n"
}

main() {
  choice=$(menu | ${rofi_command})

  # No choice case
  if [[ -z $choice ]]; then
    exit 0
  fi

  # Random choice case
  if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
    set_wallpaper "${wallDIR}/${RANDOM_PIC}"
    picked="${wallDIR}/${RANDOM_PIC}"
    return
  fi

  # Find the index of the selected file
  pic_index=-1
  for i in "${!PICS[@]}"; do
    filename=$(basename "${PICS[$i]}")
    if [[ "$filename" == "$choice"* ]]; then
      pic_index=$i
      break
    fi
  done

  if [[ $pic_index -ne -1 ]]; then
    set_wallpaper "${wallDIR}/${PICS[$pic_index]}"
    picked="${wallDIR}/${PICS[$pic_index]}"
  else
    echo "Image not found."
    exit 1
  fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

main

sleep 0.5
${SCRIPTSDIR}/PywalSwww.sh "$picked"

# Refresh.sh (pkill+relaunch waybar/rofi/swaync) was dropped here (2026-09-11)
# -- same reasoning as WallpaperRandom.sh: waybar/rofi colors are static per
# theme identity now, not wallpaper-derived, so restarting them for a plain
# wallpaper change did nothing useful except reset waybar's idle_inhibitor
# ("caffeine" toggle) back off. See WallpaperRandom.sh for the full story.
