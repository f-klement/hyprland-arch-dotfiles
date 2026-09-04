-- Window rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Replaces UserConfigs/WindowRules.conf
--
-- The old file used a pipe-delimited "class:X|title:Y|class:Z" OR syntax
-- inside a single windowrulev2 match string. The new `match` table doesn't
-- have an OR operator for combining alternatives in one rule, so each
-- alternative below is its own hl.window_rule with the same action --
-- functionally identical (any one of them matching produces the same
-- effect), just expressed as separate named rules instead of one long
-- pipe chain.
--
-- Also: --verify-config flagged that `windowrule`/`windowrulev2` in the OLD
-- hyprlang syntax were already emitting parser errors/deprecation warnings
-- on this Hyprland version even before this migration -- so several of
-- these rules were arguably not reliably applying at all. That's now moot.

local function float_rule(name, class_pat)
    hl.window_rule({ name = name, match = { class = class_pat }, float = true })
end

float_rule("float-polkit-kde",        "org.kde.polkit-kde-authentication-agent-1")
float_rule("float-nm-editor",         "nm-connection-editor")
float_rule("float-blueman",           "blueman-manager")
float_rule("float-pavucontrol",       "pavucontrol")
float_rule("float-nwg-look",          "nwg-look")
float_rule("float-qt5ct",             "qt5ct")
float_rule("float-mpv",               "mpv")
float_rule("float-rofi",              "rofi")
float_rule("float-zenity",            "zenity")
float_rule("float-yad",               "yad")
float_rule("float-swayimg",           "swayimg")
float_rule("float-vlc",               "vlc")
float_rule("float-viewnior",          "Viewnior")
float_rule("float-steam",             "steam")
float_rule("float-wine",              "wine")
float_rule("float-proton",            "proton")
float_rule("float-bottles",           "bottles")
float_rule("float-laptop-mode-tool",  "laptop-mode-tool")

hl.window_rule({ name = "pavucontrol-center", match = { class = "^(pavucontrol)$" }, center = true })

hl.window_rule({ name = "gamescope-noblur",     match = { class = "gamescope" }, no_blur = true })
hl.window_rule({ name = "gamescope-fullscreen", match = { class = "gamescope" }, fullscreen = true })

------------------------------------
---- WORKSPACE ASSIGNMENT ----
------------------------------------

hl.window_rule({ name = "ws-firefox",    match = { class = "^(firefox)$" },              workspace = "2" })
hl.window_rule({ name = "ws-firefox-esr",match = { class = "^(Firefox-esr)$" },           workspace = "2" })
hl.window_rule({ name = "ws-edge-beta",  match = { class = "^(Microsoft-edge-beta)$" },   workspace = "2" })
hl.window_rule({ name = "ws-thunar",     match = { class = "^([Tt]hunar)$" },             workspace = "3" })
hl.window_rule({ name = "ws-obs",        match = { class = "^(com.obsproject.Studio)$" }, workspace = "4" })
hl.window_rule({ name = "ws-steam",      match = { class = "^([Ss]team)$" },              workspace = "5 silent" })
hl.window_rule({ name = "ws-steam-title",match = { title = "^([Ss]team)$" },              workspace = "5 silent" })
hl.window_rule({ name = "ws-lutris",     match = { class = "^(lutris)$" },                workspace = "5 silent" })
hl.window_rule({ name = "ws-discord",    match = { class = "^(discord)$" },               workspace = "7 silent" })
hl.window_rule({ name = "ws-webcord",    match = { class = "^(WebCord)$" },                workspace = "7 silent" })
hl.window_rule({ name = "ws-audacious",  match = { class = "^([Aa]udacious)$" },           workspace = "9 silent" })

------------------------------------
---- OPACITY ----
------------------------------------
-- The old file defined several of these TWICE with different, conflicting
-- values (kitty: 0.9/0.8 then later 0.7/0.7; thunar: 0.9/0.8 then 0.9/0.7)
-- -- deduplicated to one value each. kitty keeps the more opaque 0.9/0.8
-- (it's your daily-driver terminal); thunar takes 0.9/0.7 to match the
-- convention used by everything else. Flip either back easily if you meant
-- the other value.

local function opacity_rule(name, class_pat, focused, unfocused)
    hl.window_rule({ name = name, match = { class = class_pat }, opacity = focused .. " " .. unfocused })
end

opacity_rule("opacity-rofi",        "^([Rr]ofi)$",             "0.9", "0.6")
opacity_rule("opacity-brave",       "^(Brave-browser)$",       "0.9", "0.7")
opacity_rule("opacity-brave-lower", "^(brave)$",                "0.9", "0.7")
opacity_rule("opacity-brave-dev",   "^(Brave-browser-dev)$",   "0.9", "0.7")
opacity_rule("opacity-librewolf",   "^(librewolf)$",           "0.9", "0.7")
opacity_rule("opacity-firefox",     "^(firefox)$",             "0.9", "0.7")
opacity_rule("opacity-firefox-esr", "^(Firefox-esr)$",         "0.9", "0.7")
opacity_rule("opacity-thunar",      "^([Tt]hunar)$",           "0.9", "0.7")
opacity_rule("opacity-dolphin",     "^(dolphin)$",             "0.9", "0.7")
opacity_rule("opacity-pcmanfm-qt",  "^(pcmanfm-qt)$",          "0.8", "0.6")
opacity_rule("opacity-gedit",       "^(gedit)$",               "0.9", "0.7")
opacity_rule("opacity-mousepad",    "^(mousepad)$",            "0.9", "0.7")
opacity_rule("opacity-kitty",       "^(kitty)$",               "0.9", "0.8")
opacity_rule("opacity-codium-url",  "^(codium-url-handler)$","0.9", "0.7")
opacity_rule("opacity-vscodium",    "^(VSCodium)$",            "0.9", "0.7")
opacity_rule("opacity-vscode-url",  "^(vscode-url-handler)$","0.9", "0.7")
opacity_rule("opacity-code-url",    "^(code-url-handler)$",  "0.9", "0.7")
opacity_rule("opacity-code",        "^(code)$",                "0.9", "0.7")
opacity_rule("opacity-yad",         "^(yad)$",                 "0.9", "0.7")
opacity_rule("opacity-obs",         "^(com.obsproject.Studio)$","0.9","0.7")
opacity_rule("opacity-audacious",   "^([Aa]udacious)$",        "0.9", "0.7")

------------------------------------
---- PICTURE IN PICTURE ----
------------------------------------

local pipMatch = { title = "^(Picture-in-Picture)$" }
hl.window_rule({ name = "pip-opacity", match = pipMatch, opacity = "0.95 0.75" })
hl.window_rule({ name = "pip-pin",     match = pipMatch, pin = true })
hl.window_rule({ name = "pip-float",   match = pipMatch, float = true })
hl.window_rule({ name = "pip-size",    match = pipMatch, size = "25% 25%" })
hl.window_rule({ name = "pip-move",    match = pipMatch, move = "72% 7%" })

------------------------------------
---- MISC (from the shipped example config) ----
------------------------------------

-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
