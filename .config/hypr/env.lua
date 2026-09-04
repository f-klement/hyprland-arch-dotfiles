-- Environment variables
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Was "qt5ct" -- but the qt5ct package wasn't installed at the time, so
-- every Qt app was failing to load that platformtheme plugin and silently
-- falling back to an unthemed default (no Kvantum, no dark palette).
-- qt6ct is installed and has a full Tokyo Night config at
-- ~/.config/qt6ct/qt6ct.conf (style=kvantum) -- set as the session default
-- since virtually every real app on this Plasma 6 system is Qt6.
--
-- qt5ct is now installed too (also pre-configured for Tokyo Night, see
-- ~/.config/qt5ct/qt5ct.conf) but can't just be added as a second value
-- here -- QT_QPA_PLATFORMTHEME has no fallback-list syntax, and Qt5 vs Qt6
-- apps each only look in their own major-version's plugin directory, so
-- one global env var can only ever serve one major version. For any Qt5
-- app you actually run, launch it through scripts/Qt5App.sh instead (or
-- I can wire a specific app in as a keybind/window rule once you name it).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")

-- NOTE: GTK_THEME is deliberately NOT set here. initial-boot.sh persists the
-- GTK theme via `gsettings set org.gnome.desktop.interface gtk-theme ...`,
-- which is the single source of truth now. The old config force-set
-- GTK_THEME=Dracula here, which silently overrode the Tokyo Night gsettings
-- value on every single GTK app launch -- that mismatch was the main cause
-- of the "half Dracula, half Tokyo Night" look. Removing it also means
-- nwg-look/GTK theme switches at runtime stick instead of being fought.

-- NOTE: the old file also had `env = debug:disable_logs = false` and
-- `env = no_cursor_warps = 0` and `env = enable_hyprcursor, 1` here.
-- Those are config keys (debug.disable_logs, cursor.no_warps,
-- cursor.enable_hyprcursor), not environment variables -- as `env =`
-- lines they were silently no-ops. Moved to settings.lua as real config.

-- Cursor size for both hyprcursor and XWayland/toolkit apps
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- NVIDIA-only workarounds -- this machine is Intel iGPU (Raptor Lake Iris Xe,
-- i915), so these must stay OFF. WLR_NO_HARDWARE_CURSORS=1 forces the cursor
-- to be composited in software every frame instead of using the hardware
-- cursor plane -- a real, constant, and entirely pointless GPU/CPU cost on
-- non-NVIDIA hardware.
--
-- IMPORTANT: this is explicitly forced to "0" rather than just omitted.
-- /etc/environment sets WLR_NO_HARDWARE_CURSORS=1 SYSTEM-WIDE via pam_env,
-- which every login session (including this one) inherits before Hyprland
-- even starts. Simply not setting it here would leave that inherited "1" in
-- place. Setting it explicitly overrides the inherited value for Hyprland
-- and everything it launches, without touching the system-wide file (which
-- may be there for some other reason, and needs root to edit anyway -- say
-- the word if you want that removed system-wide instead).
hl.env("WLR_NO_HARDWARE_CURSORS", "0")
--
-- Uncomment the block below only if this config is ever used on an NVIDIA GPU
-- (and remove the "0" override above).
--
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
-- hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")
-- hl.env("NVD_BACKEND", "direct")
