-- Environment variables
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
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
-- i915), so these must stay OFF. WLR_NO_HARDWARE_CURSORS=1 in particular was
-- previously set unconditionally and forces the cursor to be composited in
-- software every frame instead of using the hardware cursor plane -- a real,
-- constant, and entirely pointless GPU/CPU cost on non-NVIDIA hardware.
-- Uncomment the block below only if this config is ever used on an NVIDIA GPU.
--
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
-- hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")
-- hl.env("NVD_BACKEND", "direct")
