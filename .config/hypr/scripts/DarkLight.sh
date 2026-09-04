#!/bin/bash
## Theme toggle (waybar's custom/light_dark module, left-click)
## Tokyo Night <-> Rose Pine
##
## This used to be a real dark/light-mode switch: GTK theme, icon theme,
## Kvantum, qt5ct/qt6ct color scheme, and rofi all got re-picked by
## searching for "*Dark*"/"*Light*"-keyword-matching installed themes
## (randomly, when more than one matched). That's rebuilt here as a
## deterministic two-way toggle between two specific identities instead,
## per request, but there's a real scope limit: there's no Rose Pine GTK
## theme, icon theme, Kvantum theme, or qt5ct/qt6ct color scheme installed
## on this system -- only a waybar stylesheet and (now) a rofi color file.
## So this toggles waybar + rofi + wallpaper mood + notification tint;
## GTK/icons/Kvantum/Qt stay on Tokyo Night in both states. Say the word
## if you want me to source and install proper Rose Pine GTK/icon/Kvantum
## theme packages to close that gap for real.

wallpaper_base_path="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
swaync_style="$HOME/.config/swaync/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
notif="$HOME/.config/swaync/images/bell.png"
state_file="$HOME/.cache/.theme_mode"

pkill swaybg

setwallpaper() {
    hyprctl hyprpaper preload "$1" > /dev/null
    hyprctl hyprpaper wallpaper ",$1" > /dev/null
    hyprctl hyprpaper unload all > /dev/null
}

# Determine next state
current=$(cat "$state_file" 2>/dev/null)
if [ "$current" = "rose-pine" ]; then
    next="tokyo-night"
else
    next="rose-pine"
fi

if [ "$next" = "tokyo-night" ]; then
    waybar_style="$HOME/.config/waybar/style/Tokyo-Night.css"
    rofi_theme="$HOME/.config/rofi/pywal-color/tokyo-night.rasi"
    wallpaper_dir="$dark_wallpapers"
    noti_bg="rgba(26, 27, 38, 0.85)"
    noti_bg_alt="#16161e"
else
    waybar_style="$HOME/.config/waybar/style/Rose Pine.css"
    rofi_theme="$HOME/.config/rofi/pywal-color/rose-pine.rasi"
    wallpaper_dir="$light_wallpapers"
    noti_bg="rgba(38, 35, 58, 0.85)"
    noti_bg_alt="#26233a"
fi

ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"
ln -sf "$rofi_theme" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"

# Notification tint (both palettes are dark-ish, so this is a color swap,
# not a real light/dark contrast switch)
sed -i "/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/${noti_bg};/" "${swaync_style}"
sed -i "/@define-color noti-bg-alt/s/#.*;/${noti_bg_alt};/" "${swaync_style}"

next_wallpaper="$(find "${wallpaper_dir}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
if [ -n "$next_wallpaper" ]; then
    setwallpaper "${next_wallpaper}"
fi

echo "$next" > "$state_file"

sleep 0.5
${SCRIPTSDIR}/PywalSwww.sh "$next_wallpaper"
sleep 1
${SCRIPTSDIR}/Refresh.sh

notify-send -u normal -i "$notif" "Theme: $next"

exit 0
