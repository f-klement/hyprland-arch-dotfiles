#!/bin/bash
## Theme rotation (waybar's custom/light_dark module, left-click; also the
## "Theme" tile in UserScripts/QuickSettings.py)
## Tokyo Night -> Rosé Pine Moon -> Rosé Pine Dawn -> Tokyo Night ...
##
## Rewritten 2026-09-16 from a two-way toggle into a rotation: every
## per-theme value now lives in ~/.config/hypr/themes/<name>/theme.sh (plus
## that directory's hyprlock.conf / swaync.css / wlogout.css colour files),
## so adding a fourth theme is a new directory + one entry in THEMES below.
## The state name is what ~/.cache/.theme_mode stores and what pane.py /
## QuickSettings.py / settings.lua read; "rose-pine" still means Moon.
##
## A full identity switch: waybar, rofi, wallpaper mood, swaync, wlogout,
## hyprlock, Hyprland window borders, kitty, GTK3/GTK4 theme+accent, icon
## theme, Kvantum, qt5ct/qt6ct colour scheme, kdeglobals (Plasma colour
## scheme), Thunderbird userChrome. Moon assets came straight from the
## official rose-pine GitHub org (github.com/rose-pine/gtk, /kvantum,
## /kitty) into ~/.themes, ~/.icons, ~/.config/Kvantum, ~/.config/gtk-4.0;
## Dawn ones the same way (gtk release v2.2.0, kvantum dist, kitty dist),
## with the hand-made pieces (rofi, qt5ct, Plasma, Thunderbird, gtk-4.0
## accent, colour files) derived role-for-role from the Moon versions.
## The one thing intentionally left alone: cursor stays Dracula in every
## state, by request from earlier in this theming pass.
##
## Usage: DarkLight.sh            rotate to the next theme
##        DarkLight.sh <name>     jump to that theme (tokyo-night | rose-pine | rose-pine-dawn)

THEMES=(tokyo-night rose-pine rose-pine-dawn)

wallpaper_base_path="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
# curated per-theme set (2026-09-16), listed by the Rosé Pine theme.sh files.
# theme.sh sets wallpaper_dirs=(...) -- one or more of these; WallpaperRandom.sh
# defines the same three variables and reads the same array.
rose_pine_wallpapers="$HOME/Pictures/wallpapers/rose-pine"
themes_dir="$HOME/.config/hypr/themes"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
notif="$HOME/.config/swaync/images/bell.png"
state_file="$HOME/.cache/.theme_mode"

pkill swaybg

setwallpaper() {
    hyprctl hyprpaper preload "$1" > /dev/null
    hyprctl hyprpaper wallpaper ",$1" > /dev/null
    hyprctl hyprpaper unload all > /dev/null
}

# Determine the next state. Tokyo Night is the default: an empty/missing
# state_file (fresh install, cache cleared) or an unknown value resolves to
# the first entry of THEMES.
current=$(cat "$state_file" 2>/dev/null)
if [ -n "$1" ]; then
    next="$1"
else
    next="${THEMES[0]}"
    for i in "${!THEMES[@]}"; do
        if [ "${THEMES[$i]}" = "$current" ]; then
            next="${THEMES[$(( (i + 1) % ${#THEMES[@]} ))]}"
            break
        fi
    done
fi
theme_dir="$themes_dir/$next"
if [ ! -f "$theme_dir/theme.sh" ]; then
    notify-send -u critical -i "$notif" "Theme: unknown '$next'" "no $theme_dir/theme.sh"
    exit 1
fi
# shellcheck source=/dev/null
. "$theme_dir/theme.sh"

# waybar/style.css: was `ln -sf` (symlink-swap). Changed to a content copy
# (2026-09-11) -- waybar/config has "reload_style_on_change": true, and
# waybar watches the *resolved* target file, so swapping the symlink was
# never detected; overwriting style.css's content is what it reacts to
# ("Reloading style, file changed" in `waybar -l debug`). Written to a temp
# file and mv'd into place so the watcher never sees a half-written file.
# No waybar restart means the idle_inhibitor ("caffeine") survives a theme
# switch. (The two theme stylesheets share one body -- only the palette
# header differs -- so the bar's geometry is identical in every state; see
# waybar/proposals/README.md.)
cp "$waybar_style" "$HOME/.config/waybar/style.css.tmp" && mv "$HOME/.config/waybar/style.css.tmp" "$HOME/.config/waybar/style.css"
ln -sf "$rofi_theme" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
ln -sf "$kitty_theme" "$HOME/.dotfiles/.config/kitty/theme.conf"
ln -sf "$gtk4_accent" "$HOME/.config/gtk-4.0/gtk.css"

# Per-theme colour files (2026-09-16): swaync/style.css and
# wlogout/style.css @import a colors.css symlink next to them, hyprlock.conf
# `source`s hyprlock-colors.conf -- all three re-pointed here.
ln -sfn "$theme_dir/swaync.css"   "$HOME/.config/swaync/colors.css"
ln -sfn "$theme_dir/wlogout.css"  "$HOME/.config/wlogout/colors.css"
ln -sfn "$theme_dir/hyprlock.conf" "$HOME/.config/hypr/hyprlock-colors.conf"

# Hyprland window borders: settings.lua reads border_active/border_inactive
# from theme.sh on (re)load; this applies them to the running session.
# (`hyprctl keyword` is refused under the Lua config -- "keyword can't work
# with non-legacy parsers. Use eval." -- so it goes through hl.config.)
hyprctl eval "hl.config({ general = { col = { active_border = \"$border_active\", inactive_border = \"$border_inactive\" } } })" > /dev/null

# kitty reloads its config on SIGUSR1, so open terminals follow the switch.
pkill -USR1 -x kitty 2>/dev/null

# Claude Code keeps its UI theme ("dark"/"light"/...-daltonized/-ansi) in
# ~/.claude.json alongside a lot of other state, so edit just that key,
# atomically (Claude Code itself rewrites the file often). Sessions started
# after the switch pick it up; a running one needs /config (or a restart).
if [ -n "$claude_theme" ] && [ -f "$HOME/.claude.json" ]; then
    python3 - "$claude_theme" <<'PY'
import json, os, sys, tempfile
p = os.path.expanduser("~/.claude.json")
try:
    with open(p) as f: d = json.load(f)
except (OSError, ValueError):
    sys.exit(0)
if d.get("theme") != sys.argv[1]:
    d["theme"] = sys.argv[1]
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(p), prefix=".claude.json.")
    with os.fdopen(fd, "w") as f: json.dump(d, f, indent=2)
    os.chmod(tmp, 0o600); os.replace(tmp, p)
PY
fi

# GTK (both the gsettings/dconf path GTK4+libadwaita apps read via the xdg
# desktop portal, and gtk-3.0/settings.ini, which GTK3 apps read directly
# -- there's no gnome-settings-daemon on this system keeping the two in
# sync automatically, so both need setting)
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$icon_theme/" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
# GTK3 apps pick the dark variant of a theme from this key; the Dawn theme
# ships no dark variant, so it stays plain there, but Tokyo Night / Moon
# want it on.
if [ "$color_scheme" = "prefer-dark" ]; then dark=true; else dark=false; fi
sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark/" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# Kvantum + qt5ct/qt6ct
kvantummanager --set "$kvantum_theme"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$HOME/.config/qt5ct/colors/$qt_color_scheme|" "$HOME/.config/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$HOME/.config/qt6ct/colors/$qt_color_scheme|" "$HOME/.config/qt6ct/qt6ct.conf"
sed -i "s/^icon_theme=.*/icon_theme=$icon_theme/" "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"

# hyprpolkitagent (2026-09-16): the polkit password dialog is a Qt6/QML
# window whose colours come from SystemPalette, i.e. the qt6ct palette Qt
# reads once at process start. The agent is a long-lived systemd user
# service started at login, so without this it keeps painting the palette
# of whatever theme was active at login (seen: still Moon/Tokyo Night
# after switching to Dawn). Restart is instant and harmless -- polkit
# just re-registers the agent; nothing is lost unless a prompt is open
# at this exact moment.
systemctl --user restart hyprpolkitagent.service 2>/dev/null

# KDE Frameworks apps (Dolphin, Ark, systemsettings, ...) -- added
# (2026-09-11). These read ~/.config/kdeglobals for their color scheme via
# KColorScheme, which is completely separate from qt6ct/Kvantum (Kvantum
# controls widget *style* -- button shapes, scrollbars, menu chrome --
# kdeglobals controls the actual color *palette* KDE-aware widgets use).
# plasma-apply-colorscheme is the proper tool (not hand-editing kdeglobals
# with sed): it applies every relevant kdeglobals section from one of the
# schemes in ~/.local/share/color-schemes/ (TokyoNight, RosePineMoon,
# RosePineDawn -- built to match this system's established palette, same
# hex values as kitty/gtk-4.0's accent files) and notifies running KDE
# apps live via KGlobalSettings, no restart needed for most of them.
plasma-apply-colorscheme "$kde_color_scheme" >/dev/null 2>&1
kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icon_theme"

# Dolphin's file list kept rendering an unstyled light-gray row background
# despite kdeglobals being correct. Root cause: QT_QPA_PLATFORMTHEME=qt6ct
# doesn't fully replicate the native KDEPlasmaPlatformTheme6 plugin's
# KColorScheme integration KDE Frameworks widgets read from. Dolphin is
# launched via scripts/KdeApp.sh (QT_QPA_PLATFORMTHEME=kde) -- but that
# plugin looks at kdeglobals' [KDE] widgetStyle for the widget *style*, and
# with none set fell back to Breeze instead of Kvantum. This is the other
# half.
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum

# Thunderbird (2026-09-11): a proper WebExtension theme (manifest.json next
# to the userChrome.css files) installed fine but never rendered; the
# userChrome.css (toolkit.legacyUserProfileCustomizations.stylesheets=true
# in the profile's user.js) is what's real. Requires closing Thunderbird
# first -- it doesn't watch userChrome.css for changes.
tb_profile="$HOME/.thunderbird/uwfxwrvr.default-release"
if [ -d "$tb_profile/chrome" ]; then
    ln -sf "$tb_userchrome" "$tb_profile/chrome/userChrome.css"
fi

next_wallpaper="$(find "${wallpaper_dirs[@]}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 2>/dev/null | shuf -n1 -z | xargs -0)"
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
# wait until the new swaync owns org.freedesktop.Notifications, otherwise
# the notify-send below races it and fails with NameHasNoOwner
for _ in $(seq 1 30); do swaync-client --count > /dev/null 2>&1 && break; sleep 0.1; done

# radiotray-ng (2026-09-16): its tray icon is a -symbolic SVG that waybar
# recolours with the bar's CSS text colour -- but only when the item
# (re)sends its icon, and radiotray-ng does that on play/stop alone, so
# after the style swap above it would keep the old theme's colour. Nudge
# it: a playing station gets a stop/play round-trip (a ~1 s gap, keeps the
# sleep timer etc.), a stopped one is simply restarted.
if pgrep -x radiotray-ng > /dev/null; then
    rtng="busctl --user --timeout=3 call com.github.radiotray_ng /com/github/radiotray_ng com.github.radiotray_ng"
    if $rtng get_player_state 2>/dev/null | grep -q '\\"state\\" : \\"\(playing\|buffering\|connecting\)\\"'; then
        $rtng stop > /dev/null 2>&1
        sleep 0.3
        $rtng play > /dev/null 2>&1
    else
        pkill -x radiotray-ng
        sleep 0.3
        setsid radiotray-ng > /dev/null 2>&1 &
    fi
fi

notify-send -u normal -i "$notif" "Theme: $label"

exit 0
