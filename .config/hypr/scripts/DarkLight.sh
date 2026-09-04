#!/bin/bash
## Theme toggle (waybar's custom/light_dark module, left-click)
## Tokyo Night <-> Rose Pine (Moon)
##
## Now a full identity switch: waybar, rofi, wallpaper mood, notification
## tint, GTK3/GTK4 theme+accent, icon theme, Kvantum, and qt5ct/qt6ct
## color scheme. Rose Pine assets were sourced straight from the official
## rose-pine GitHub org (github.com/rose-pine/gtk, github.com/rose-pine/
## kvantum) and installed to ~/.themes, ~/.icons, ~/.config/Kvantum,
## ~/.config/gtk-4.0 -- no AUR/sudo needed, those ship plain theme files.
## The one thing intentionally left alone: cursor stays Dracula in both
## states, by request from earlier in this theming pass.

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
    gtk_theme="Tokyonight-Dark-BL-LB"
    icon_theme="Tela-purple-dark"
    kvantum_theme="Tokyo-Night"
    qt_color_scheme="Tokyo-Night.conf"
    gtk4_accent="$HOME/.config/gtk-4.0/tokyo-night-accent.css"
    color_scheme="prefer-dark"
else
    waybar_style="$HOME/.config/waybar/style/Rose Pine.css"
    rofi_theme="$HOME/.config/rofi/pywal-color/rose-pine.rasi"
    wallpaper_dir="$light_wallpapers"
    noti_bg="rgba(38, 35, 58, 0.85)"
    noti_bg_alt="#26233a"
    gtk_theme="oomox-rose-pine-moon"
    icon_theme="oomox-rose-pine-moon"
    kvantum_theme="rose-pine-moon-pine"
    qt_color_scheme="Rose-Pine-Moon.conf"
    gtk4_accent="$HOME/.config/gtk-4.0/rose-pine-moon-accent.css"
    color_scheme="prefer-dark" # both palettes are dark; there's no Rose Pine Dawn (light) asset installed
fi

ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"
ln -sf "$rofi_theme" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
ln -sf "$gtk4_accent" "$HOME/.config/gtk-4.0/gtk.css"

# GTK (both the gsettings/dconf path GTK4+libadwaita apps read via the xdg
# desktop portal, and gtk-3.0/settings.ini, which GTK3 apps read directly
# -- there's no gnome-settings-daemon on this system keeping the two in
# sync automatically, so both need setting)
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# Kvantum + qt5ct/qt6ct
kvantummanager --set "$kvantum_theme"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$HOME/.config/qt5ct/colors/$qt_color_scheme|" "$HOME/.config/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$HOME/.config/qt6ct/colors/$qt_color_scheme|" "$HOME/.config/qt6ct/qt6ct.conf"
sed -i "s/^icon_theme=.*/icon_theme=$icon_theme/" "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

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
