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

# Determine next state. Tokyo Night is the default: an empty/missing
# state_file (fresh install, cache cleared) or anything other than an
# explicit saved "tokyo-night" resolves to tokyo-night, not rose-pine.
current=$(cat "$state_file" 2>/dev/null)
if [ "$current" = "tokyo-night" ]; then
    next="rose-pine"
else
    next="tokyo-night"
fi

if [ "$next" = "tokyo-night" ]; then
    waybar_style="$HOME/.config/waybar/style/Tokyo-Night.css"
    rofi_theme="$HOME/.config/rofi/pywal-color/tokyo-night.rasi"
    kitty_theme="tokyo-night.conf"
    wallpaper_dir="$dark_wallpapers"
    noti_bg="rgba(26, 27, 38, 0.85)"
    noti_bg_alt="#16161e"
    gtk_theme="Tokyonight-Dark-BL-LB"
    # BUG FOUND (2026-09-11): "Tela-purple-dark" isn't installed anywhere on
    # this system (not in ~/.icons, not in /usr/share/icons, not a package) --
    # every app was silently falling back to its toolkit's default icon set
    # (Adwaita/breeze) instead, which is very likely what read as "GTK/Qt
    # apps don't match the theme": window chrome and colors were correct,
    # but every icon was the wrong theme's. "Tokyonight-Dark" (an actual
    # installed Suru-based icon set, ~/.icons/Tokyonight-Dark) is what's
    # really there and is the correct counterpart to gtk_theme above.
    icon_theme="Tokyonight-Dark"
    kvantum_theme="Tokyo-Night"
    qt_color_scheme="Tokyo-Night.conf"
    gtk4_accent="$HOME/.config/gtk-4.0/tokyo-night-accent.css"
    kde_color_scheme="TokyoNight"
    tb_userchrome="$HOME/.dotfiles/.local/share/thunderbird-themes/tokyo-night/userChrome.css"
    color_scheme="prefer-dark"
else
    waybar_style="$HOME/.config/waybar/style/Rose Pine.css"
    rofi_theme="$HOME/.config/rofi/pywal-color/rose-pine.rasi"
    kitty_theme="rose-pine-moon.conf"
    wallpaper_dir="$light_wallpapers"
    noti_bg="rgba(38, 35, 58, 0.85)"
    noti_bg_alt="#26233a"
    gtk_theme="oomox-rose-pine-moon"
    icon_theme="oomox-rose-pine-moon"
    kvantum_theme="rose-pine-moon-pine"
    qt_color_scheme="Rose-Pine-Moon.conf"
    gtk4_accent="$HOME/.config/gtk-4.0/rose-pine-moon-accent.css"
    kde_color_scheme="RosePineMoon"
    tb_userchrome="$HOME/.dotfiles/.local/share/thunderbird-themes/rose-pine-moon/userChrome.css"
    color_scheme="prefer-dark" # both palettes are dark; there's no Rose Pine Dawn (light) asset installed
fi

# waybar/style.css: was `ln -sf` (symlink-swap). Changed to a content copy
# (2026-09-11) -- waybar/config now has "reload_style_on_change": true,
# which hot-reloads the bar without a restart (verified via
# `waybar -l debug`: it watches the *resolved* target file, so swapping
# which file the symlink points to was invisible to it -- neither file's
# content ever changed. Overwriting style.css's own content in place is
# what it actually detects, confirmed by "Reloading style, file changed"
# in the debug log). This is also why the idle_inhibitor ("caffeine"
# toggle) survives a theme switch now: no waybar restart means no
# idle_inhibitor module getting recreated from scratch. See below for the
# matching change to the final refresh (skips waybar entirely now).
cp "$waybar_style" "$HOME/.config/waybar/style.css"
ln -sf "$rofi_theme" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
ln -sf "$kitty_theme" "$HOME/.dotfiles/.config/kitty/theme.conf"
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

# KDE Frameworks apps (Dolphin, Ark, systemsettings, ...) -- added
# (2026-09-11). These read ~/.config/kdeglobals for their color scheme via
# KColorScheme, which is completely separate from qt6ct/Kvantum (Kvantum
# controls widget *style* -- button shapes, scrollbars, menu chrome --
# kdeglobals controls the actual color *palette* KDE-aware widgets use).
# kdeglobals had never been touched by any of this system's theming: it
# was still stock Breeze Dark defaults, with an [Icons] Theme= pointing at
# the same phantom "Tela-purple-dark" fixed above for everything else --
# very likely the main reason Dolphin specifically looked out of place
# even with Kvantum/qt6ct otherwise correct. plasma-apply-colorscheme is
# the proper tool (not hand-editing kdeglobals with sed): it applies every
# relevant kdeglobals section from one of the two schemes in
# ~/.local/share/color-schemes/ (TokyoNight.colors, RosePineMoon.colors --
# built to match this system's established palette, same hex values as
# kitty/gtk-4.0's accent files) and notifies running KDE apps live via
# KGlobalSettings, no restart needed for most of them.
plasma-apply-colorscheme "$kde_color_scheme" >/dev/null 2>&1
kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icon_theme"

# Still wasn't enough on its own -- Dolphin's file list kept rendering an
# unstyled light-gray row background (found via screenshot + pixel
# sampling) despite kdeglobals now being correct. Root cause turned out to
# be QT_QPA_PLATFORMTHEME=qt6ct itself: it's a solid generic Qt platform
# theme but doesn't fully replicate the native KDEPlasmaPlatformTheme6
# plugin's KColorScheme integration that KDE Frameworks widgets (like
# Dolphin's KItemListView) actually read from. Dolphin is now launched via
# scripts/KdeApp.sh, which sets QT_QPA_PLATFORMTHEME=kde instead -- but
# that plugin looks at kdeglobals' [KDE] widgetStyle for which widget
# *style* to use, and with none set it fell back to Breeze instead of
# Kvantum. This is the other half: without it, Dolphin would have the
# right colors but the wrong (unstyled Breeze) widget shapes.
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum

# Thunderbird (2026-09-11): was still on "Purple Praline", a light AMO
# theme, completely unrelated to the rest of this desktop's identity.
# Tried building a proper WebExtension theme first (manifest.json in the
# same directory as the userChrome.css files linked below) -- got it
# fully, correctly installed and active per Thunderbird's own addon
# database (extensions.json: active=true, userDisabled=false), confirmed
# across multiple clean restarts and a startupCache wipe, and it still
# never actually rendered. Left installed but inactive rather than
# fighting it further. userChrome.css (toolkit.legacyUserProfileCustomizations
# .stylesheets=true, set once in the profile's user.js) is what's real --
# found the right selectors by launching Thunderbird repeatedly with
# bright throwaway colors and screenshotting to see what lit up, same
# approach as everything else fixed by actually looking this session.
# Requires closing Thunderbird first -- it doesn't watch userChrome.css
# for changes the way waybar now does for style.css.
tb_profile="$HOME/.thunderbird/uwfxwrvr.default-release"
if [ -d "$tb_profile/chrome" ]; then
    ln -sf "$tb_userchrome" "$tb_profile/chrome/userChrome.css"
fi

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

# Was Refresh.sh, which also kills and relaunches waybar -- no longer
# needed (see the style.css comment above) and that restart was exactly
# what reset the idle_inhibitor on every theme switch. rofi and swaync
# still need a real restart: rofi picks up pywal-theme.rasi's new symlink
# target on next launch (no running instance to hot-reload), and swaync
# has no equivalent watch-and-reload for its own style.css.
pkill rofi 2>/dev/null
sleep 0.3
pkill swaync 2>/dev/null
sleep 0.5
swaync > /dev/null 2>&1 &

notify-send -u normal -i "$notif" "Theme: $next"

exit 0
