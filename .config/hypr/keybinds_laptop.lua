-- Laptop-specific keybinds
-- Replaces UserConfigs/Laptops.conf
-- See also keybinds.lua for the base binds.

local home       = os.getenv("HOME")
local mainMod    = "SUPER"
local scriptsDir = home .. "/.config/hypr/scripts"

local function combo(mods, k)
    if mods == "" then return k end
    return mods .. " + " .. k
end

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"))
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"))
hl.bind("XF86TouchpadToggle",    hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh")) -- disable touchpad

-- ASUS-only hotkeys from the original template (rog-control-center, asusctl)
-- -- this is a TUXEDO machine, neither binary is installed, so these were
-- dead. Left here commented in case this config ever runs on ASUS hardware.
-- hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center")) -- Armoury Crate button
-- hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n")) -- FN+F4 keyboard RGB profile
-- hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))  -- FN+F5 fan profile

-- Screenshot keybinds for laptops without a dedicated PrintScreen key
hl.bind(combo(mainMod, "F6"),         hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"))
hl.bind(combo(mainMod, "SHIFT + F6"), hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"))
hl.bind(combo(mainMod, "CTRL + F6"),  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"))
hl.bind(combo(mainMod, "ALT + F6"),   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6",                   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"))

-- Lid-switch handling: disabled by default in the old config too (all
-- commented out there). The old trick worked by having a bind literally
-- rewrite UserConfigs/LaptopDisplay.conf with a new `monitor = ...` line
-- and relying on it being re-sourced -- there's no equivalent "rewrite a
-- sourced file" trick in Lua, and there doesn't need to be: a lid-switch
-- bind can just call hl.monitor({...}) directly at runtime. Example, if
-- you want the laptop panel disabled whenever the lid is closed:
--
-- hl.bind("switch:off:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", disabled = true })
-- end, { locked = true })
-- hl.bind("switch:on:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- end, { locked = true })
