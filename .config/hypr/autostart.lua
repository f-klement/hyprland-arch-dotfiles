-- Autostart
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- hl.on("hyprland.start", ...) is the Lua equivalent of the old
-- `exec-once = ...` lines: it fires exactly once, on compositor start,
-- and (unlike a bare top-level hl.exec_cmd call) does NOT re-run on
-- `hyprctl reload`.

local userScripts  = os.getenv("HOME") .. "/.config/hypr/UserScripts"
local scriptsDir   = os.getenv("HOME") .. "/.config/hypr/scripts"
local wallDir      = os.getenv("HOME") .. "/Pictures/wallpapers"

hl.on("hyprland.start", function()
    -- Session plumbing
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Polkit agent (was the KDE one; hyprpolkitagent is the Hypr-ecosystem
    -- native equivalent -- lighter, no KDE Frameworks pulled in just for
    -- this. Needs `sudo pacman -S hyprpolkitagent`.)
    hl.exec_cmd("hyprpolkitagent")

    -- Bar, tray, notifications
    hl.exec_cmd("waybar -c " .. os.getenv("HOME") .. "/.dotfiles/.config/waybar/config")
    hl.exec_cmd("nm-applet --indicator")
    -- swaync is the notification daemon in use (mako isn't installed --
    -- the old config exec'd it anyway, which just silently failed every boot)
    hl.exec_cmd("swaync")
    -- Internet radio, tray-only (no window). Custom icon in
    -- radiotray-ng.json points at the active icon theme's own
    -- internet-radio-symbolic glyph so it blends in next to nm-applet.
    hl.exec_cmd("radiotray-ng")

    -- Misc daemons
    -- run_backup.sh autostart disabled by request (2026-09-06) -- was
    -- launched both from here and from the XDG autostart .desktop
    -- (~/.config/autostart/run_backup.sh.desktop, now Hidden=true), so
    -- both had to go to actually stop it running at login.
    -- Was wlsunset -l 48.2 -L 16.3 (real lat/long solar calculation).
    -- hyprsunset has no lat/long mode -- see hyprsunset.conf for the
    -- fixed-time-profile trade-off this swap made. Needs
    -- `sudo pacman -S hyprsunset`.
    hl.exec_cmd("hyprsunset")
    -- NOTE: was `tuxedo-control-center` (no flag) -- that launches the full
    -- Electron window in the foreground on every login, duplicating what
    -- the tray already does. The tray-only autostart entry
    -- (~/.config/autostart/tuxedo-control-center-tray.desktop, which runs
    -- `tuxedo-control-center --tray`) already covers this in the
    -- background, so the redundant foreground launch was dropped here.
    -- The actual power-profile daemon (tccd.service) is a separate
    -- systemd system service, unaffected by this.
    hl.exec_cmd("batsignal -b")

    -- Clipboard history. The old config started THREE watchers: one
    -- generic `wl-paste --watch cliphist store` plus the two typed ones
    -- below -- the generic one is redundant with the typed pair (which is
    -- cliphist's own recommended setup, one process per mime class) and
    -- was just tripling clipboard-watch overhead and writing duplicate
    -- history entries. Keeping only the typed pair.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Wallpaper daemon. Was written for `swww`, briefly moved to `awww`
    -- (neither installed/right long-term) -- now hyprpaper, the Hypr
    -- ecosystem's own minimal wallpaper daemon. No transition/crossfade
    -- support (hard cut only), by design -- that trade-off was made
    -- deliberately. Needs `sudo pacman -S hyprpaper`.
    hl.exec_cmd("hyprpaper")

    -- Wallpaper: single mechanism now (see keybinds.lua / SUPER+W for the
    -- manual picker). This loop sets an initial wallpaper itself on its
    -- very first iteration, then rotates every 30 min -- the old config's
    -- extra one-shot `waypaper --random` at startup was fighting it for
    -- the first wallpaper and wasn't adding anything.
    hl.exec_cmd(userScripts .. "/WallpaperAutoChange.sh " .. wallDir)

    -- Cursor stays on Dracula-cursors (kept as-is, by request -- everything
    -- else converged on Tokyo Night, but not the cursor).
    -- NOTE: the old line was `exec-once = hyperctl setcursor ...` --
    -- "hyperctl" is a typo for "hyprctl", so this was silently failing
    -- every single boot and hyprcursor was never actually being told to
    -- switch; only the GTK-side gsettings call below was taking effect.
    -- Also fixed "Dracula-cursor" -> "Dracula-cursors" (plural) to match
    -- the theme's actual Name= (the singular form doesn't exist as an
    -- installed theme, so hyprctl would look up a set that doesn't exist).
    hl.exec_cmd("hyprctl setcursor Dracula-cursors 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Dracula-cursors")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

    hl.exec_cmd("XDG_MENU_PREFIX=arch- kbuildsycoca6")

    -- Idle handling: was swayidle with lock-only at 15min (no DPMS-off, no
    -- suspend -- meaning an idle unplugged laptop just stayed fully lit
    -- and awake indefinitely). Now hypridle, staggered per hypridle.conf:
    -- lock at 15min, screen off at 20min, suspend at 30min. Needs
    -- `sudo pacman -S hypridle hyprlock` (hypridle's lock_cmd calls
    -- hyprlock, see hypridle.conf/hyprlock.conf).
    hl.exec_cmd("hypridle")

    -- AC/battery-aware power tuning (blur + tccd profile). Long-running
    -- watcher, not a one-shot -- see the script header for what it does and
    -- why (power-draw investigation, 2026-09-06).
    hl.exec_cmd(scriptsDir .. "/PowerAutoTune.sh")
end)
