-- Autostart
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- hl.on("hyprland.start", ...) is the Lua equivalent of the old
-- `exec-once = ...` lines: it fires exactly once, on compositor start,
-- and (unlike a bare top-level hl.exec_cmd call) does NOT re-run on
-- `hyprctl reload`.

local scriptsDir   = os.getenv("HOME") .. "/.config/hypr/scripts"
local userScripts  = os.getenv("HOME") .. "/.config/hypr/UserScripts"
local wallDir      = os.getenv("HOME") .. "/Pictures/wallpapers"

hl.on("hyprland.start", function()
    -- Session plumbing
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Polkit agent
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Bar, tray, notifications
    hl.exec_cmd("waybar -c " .. os.getenv("HOME") .. "/.dotfiles/.config/waybar/config")
    hl.exec_cmd("nm-applet --indicator")
    -- swaync is the notification daemon in use (mako isn't installed --
    -- the old config exec'd it anyway, which just silently failed every boot)
    hl.exec_cmd("swaync")

    -- Backup + misc daemons
    hl.exec_cmd("/Storage/Data/run_backup.sh")
    hl.exec_cmd("wlsunset -l 48.2 -L 16.3")
    hl.exec_cmd("tuxedo-control-center")
    hl.exec_cmd("batsignal -b")

    -- Clipboard history. The old config started THREE watchers: one
    -- generic `wl-paste --watch cliphist store` plus the two typed ones
    -- below -- the generic one is redundant with the typed pair (which is
    -- cliphist's own recommended setup, one process per mime class) and
    -- was just tripling clipboard-watch overhead and writing duplicate
    -- history entries. Keeping only the typed pair.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Wallpaper: single mechanism now (see keybinds.lua / SUPER+W for the
    -- manual one-shot picker). This loop sets an initial wallpaper itself
    -- on its very first iteration, then rotates every 30 min -- the old
    -- config's extra one-shot `waypaper --random` at startup was fighting
    -- it for the first wallpaper and wasn't adding anything.
    hl.exec_cmd(userScripts .. "/WallpaperAutoChange.sh " .. wallDir)

    -- Cursor theme (Tokyo Night set, see UserSettings comment for theme
    -- rationale; Bibata-Modern-Ice is the closest installed cursor set --
    -- there's no dedicated Tokyo Night cursor theme installed here).
    -- NOTE: the old line was `exec-once = hyperctl setcursor ...` --
    -- "hyperctl" is a typo for "hyprctl", so this was silently failing
    -- every single boot and hyprcursor was never actually being told to
    -- switch; only the GTK-side gsettings call below was taking effect.
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

    hl.exec_cmd("XDG_MENU_PREFIX=arch- kbuildsycoca6")

    -- Lock on idle only (see UserScripts/WallpaperAutoChange.sh's pywal
    -- refresh for why there's no separate DPMS-off timeout configured here
    -- -- kept identical to the previous behaviour)
    hl.exec_cmd("swayidle -w timeout 900 " .. scriptsDir .. "/LockScreen.sh")
end)
