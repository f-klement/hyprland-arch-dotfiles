-- Hyprland Lua config -- entry point
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Migrated from the old hyprland.conf + configs/*.conf + UserConfigs/*.conf
-- tree (JaKooLit's Hyprland-Dots layout). Split into the same logical
-- pieces the old `source =` lines used, just as require()'d Lua modules
-- instead. See each file for what it replaces and what changed.

require("env")
require("monitors")
require("autostart")
require("settings")
require("keybinds")
require("keybinds_laptop")
require("windowrules")
