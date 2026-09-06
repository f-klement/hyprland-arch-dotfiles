-- Keybinds
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
-- Replaces configs/Keybinds.conf + UserConfigs/UserKeybinds.conf
--
-- A number of dead binds referencing undefined variables from the old
-- template ($WofiBig, $Wofi, $WofiBeats, $LockScreen, $Clipboard) have been
-- dropped -- they never fired (wofi isn't even installed). Where the same
-- physical key combo also had a *working* duplicate bind further down the
-- old file (Hyprland: last bind on an identical combo wins), only the
-- working one survives here, so live behaviour is unchanged. Each such
-- case is called out below.

local home        = os.getenv("HOME")
local mainMod      = "SUPER"
local scriptsDir   = home .. "/.config/hypr/scripts"
local userScripts  = home .. "/.config/hypr/UserScripts"

local files    = "dolphin"
local browser  = "brave"
local term     = "kitty"
local mail     = "thunderbird"
local editor   = "zeditor"

-- helper just for readability below; builds "MOD1 + MOD2 + KEY"
local function combo(mods, k)
    if mods == "" then return k end
    return mods .. " + " .. k
end

------------------------------------
---- APPS / SYSTEM ----
------------------------------------

hl.bind(combo(mainMod, "SHIFT + C"), hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(combo(mainMod, "E"),         hl.dsp.exec_cmd(editor))
hl.bind(combo(mainMod, "Q"),         hl.dsp.exec_cmd(term))
hl.bind(combo(mainMod, "D"),         hl.dsp.exec_cmd(files))
hl.bind(combo(mainMod, "M"),         hl.dsp.exec_cmd(mail))
hl.bind(combo(mainMod, "B"),         hl.dsp.exec_cmd(browser))
hl.bind(combo(mainMod, "O"),         hl.dsp.exec_cmd("obsidian"))
hl.bind(combo(mainMod, "W"),         hl.dsp.exec_cmd(userScripts .. "/WallpaperSelect.sh"))
-- ^ old bind referenced an undefined $waypapers (missing the final "s" on
-- the variable that was actually defined) so SUPER+W silently did nothing.
-- Last fix pointed it at `waypaper --random --backend swww` instead, which
-- turned out to be doubly broken: waypaper crashes outright (missing
-- Python module `screeninfo`), and "swww" isn't even the installed
-- wallpaper daemon on this system (it's `awww`, see WallpaperAutoChange.sh
-- for the full story). Pointed at WallpaperSelect.sh instead -- an
-- interactive rofi picker that actually works now that its own awww
-- references are fixed too, and is a strict upgrade over a blind random
-- pick anyway.
hl.bind("CTRL + Escape", hl.dsp.exec_cmd("stacer"))

hl.bind(combo(mainMod, "ALT + Space"), hl.dsp.exec_cmd("pkill rofi || rofi -show drun -modi drun,filebrowser,run,window"))
hl.bind("CTRL + ALT + Delete",         hl.dsp.exec_cmd("hyprctl dispatch exit 0"))
hl.bind("CTRL + ALT + L",              hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"))
hl.bind("CTRL + ALT + P",              hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"))
-- old config also bound SUPER+ALT+L to `exec wlogout` directly -- that combo
-- is reassigned to ChangeLayout.sh a few lines down (see FEATURES/EXTRAS)
-- and, since the later bind always won, wlogout was already unreachable via
-- SUPER+ALT+L in practice. It stays reachable via CTRL+ALT+P above.

------------------------------------
---- WINDOW ACTIONS ----
------------------------------------

hl.bind(combo(mainMod, "Space"),       hl.dsp.window.float({ action = "toggle" }))
hl.bind(combo(mainMod, "F"),           hl.dsp.window.fullscreen())
hl.bind(combo(mainMod, "ALT + X"),     hl.dsp.window.kill())
hl.bind(combo(mainMod, "SHIFT + Q"),   hl.dsp.window.close())
hl.bind(combo(mainMod, "SHIFT + F"),   hl.dsp.window.float({ action = "toggle" }))
hl.bind(combo(mainMod, "ALT + F"),     hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(combo(mainMod, "P"),           hl.dsp.window.pseudo()) -- dwindle only
hl.bind(combo(mainMod, "G"),           hl.dsp.group.toggle())
hl.bind("ALT + Tab",                   hl.dsp.group.next()) -- cycle focus to next window in group

------------------------------------
---- FEATURES / EXTRAS ----
------------------------------------

hl.bind(combo(mainMod, "H"),           hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh")) -- Small help file
hl.bind(combo(mainMod, "ALT + R"),     hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh")) -- Refresh waybar, swaync, rofi
hl.bind(combo(mainMod, "ALT + E"),     hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh")) -- emoji
hl.bind(combo(mainMod, "SHIFT + B"),   hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh")) -- Toggle blur settings
hl.bind(combo(mainMod, "SHIFT + G"),   hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh")) -- animations ON/OFF
hl.bind(combo(mainMod, "ALT + K"),     hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh")) -- Switch Keyboard Layout
hl.bind(combo(mainMod, "ALT + L"),     hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh")) -- Toggle Master or Dwindle Layout
hl.bind(combo(mainMod, "ALT + V"),     hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh")) -- Clipboard Manager
hl.bind(combo(mainMod, "SHIFT + N"),   hl.dsp.exec_cmd("swaync-client -t -sw")) -- swayNC panel

hl.bind(combo(mainMod, "Z"),           hl.dsp.exec_cmd(userScripts .. "/QuickEdit.sh")) -- Quick Edit Hyprland Settings
hl.bind(combo(mainMod, "SHIFT + M"),   hl.dsp.exec_cmd(userScripts .. "/RofiBeats.sh")) -- online music
hl.bind("CTRL + ALT + W",              hl.dsp.exec_cmd(userScripts .. "/WallpaperRandom.sh")) -- Random wallpapers

------------------------------------
---- LAYOUT (dwindle/master) ----
------------------------------------

hl.bind(combo(mainMod, "CTRL + D"),      hl.dsp.layout("removemaster"))
hl.bind(combo(mainMod, "I"),             hl.dsp.layout("addmaster"))
hl.bind(combo(mainMod, "J"),             hl.dsp.layout("cyclenext"))
hl.bind(combo(mainMod, "K"),             hl.dsp.layout("cycleprev"))
hl.bind(combo(mainMod, "CTRL + Return"), hl.dsp.layout("swapwithmaster"))

-- SUPER+M was bound TWICE in the old config: once to launch Thunderbird,
-- once (further down) to `hyprctl dispatch splitratio 0.3`. The later bind
-- always wins, so mail was actually dead and splitratio is what SUPER+M
-- really did. Keeping mail on SUPER+M (see APPS/SYSTEM above, restoring the
-- working shortcut) and moving splitratio to SUPER+CTRL+M, which was free.
hl.bind(combo(mainMod, "CTRL + M"), hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"))

------------------------------------
---- MEDIA / HARDWARE KEYS ----
------------------------------------

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"))
hl.bind("XF86Sleep",            hl.dsp.exec_cmd("systemctl suspend"))
hl.bind("XF86RFKill",           hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"))

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"))
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"))
hl.bind("XF86AudioStop",  hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"))

------------------------------------
---- SCREENSHOTS ----
------------------------------------

hl.bind(combo(mainMod, "Print"),         hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"))
hl.bind(combo(mainMod, "SHIFT + Print"), hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"))
hl.bind(combo(mainMod, "CTRL + Print"),  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"))
hl.bind(combo(mainMod, "ALT + Print"),   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"))
hl.bind("ALT + Print",                   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"))
hl.bind(combo(mainMod, "ALT + S"),       hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

------------------------------------
---- RESIZE / MOVE / FOCUS ----
------------------------------------

hl.bind(combo(mainMod, "CTRL + left"),  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -50 0"),  { repeating = true })
hl.bind(combo(mainMod, "CTRL + right"), hl.dsp.exec_cmd("hyprctl dispatch resizeactive 50 0"),   { repeating = true })
hl.bind(combo(mainMod, "CTRL + up"),    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"),  { repeating = true })
hl.bind(combo(mainMod, "CTRL + down"),  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"),   { repeating = true })

hl.bind(combo(mainMod, "SHIFT + left"),  hl.dsp.window.move({ direction = "l" }))
hl.bind(combo(mainMod, "SHIFT + right"), hl.dsp.window.move({ direction = "r" }))
hl.bind(combo(mainMod, "SHIFT + up"),    hl.dsp.window.move({ direction = "u" }))
hl.bind(combo(mainMod, "SHIFT + down"),  hl.dsp.window.move({ direction = "d" }))

hl.bind(combo(mainMod, "left"),  hl.dsp.focus({ direction = "l" }))
hl.bind(combo(mainMod, "right"), hl.dsp.focus({ direction = "r" }))
hl.bind(combo(mainMod, "up"),    hl.dsp.focus({ direction = "u" }))
hl.bind(combo(mainMod, "down"),  hl.dsp.focus({ direction = "d" }))

------------------------------------
---- WORKSPACES ----
------------------------------------

hl.bind(combo(mainMod, "Tab"),         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(combo(mainMod, "SHIFT + Tab"), hl.dsp.focus({ workspace = "m-1" }))

hl.bind(combo(mainMod, "SHIFT + U"), hl.dsp.window.move({ workspace = "special" }))
hl.bind(combo(mainMod, "U"),         hl.dsp.workspace.toggle_special(""))

for i = 1, 10 do
    local wsNum = i % 10 -- 10 maps to key 0
    hl.bind(combo(mainMod, tostring(wsNum)),           hl.dsp.focus({ workspace = i }))
    hl.bind(combo(mainMod, "SHIFT + " .. wsNum),       hl.dsp.window.move({ workspace = i }))
    hl.bind(combo(mainMod, "CTRL + " .. wsNum),        hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(combo(mainMod, "SHIFT + bracketleft"),  hl.dsp.window.move({ workspace = "-1" }))
hl.bind(combo(mainMod, "SHIFT + bracketright"), hl.dsp.window.move({ workspace = "+1" }))
hl.bind(combo(mainMod, "CTRL + bracketleft"),   hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(combo(mainMod, "CTRL + bracketright"),  hl.dsp.window.move({ workspace = "+1", follow = false }))

hl.bind(combo(mainMod, "mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(combo(mainMod, "mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(combo(mainMod, "period"),     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(combo(mainMod, "comma"),      hl.dsp.focus({ workspace = "e-1" }))

------------------------------------
---- MOUSE ----
------------------------------------

hl.bind(combo(mainMod, "mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(combo(mainMod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })

------------------------------------
---- SUBMAP EXAMPLE (disabled) ----
------------------------------------
-- For passthrough keyboard into a VM. Uncomment to enable:
--
-- hl.bind(mainMod .. " + ALT + P", function() hl.dispatch(hl.dsp.submap("passthru")) end)
-- hl.define_submap("passthru", function()
--     hl.bind("SUPER + ALT + P", function() hl.dispatch(hl.dsp.submap("reset")) end)
-- end)
