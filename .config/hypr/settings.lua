-- Look & feel, layout engines, misc/binds/xwayland behaviour
-- See https://wiki.hypr.land/Configuring/Basics/Variables/
-- Replaces UserConfigs/UserSettings.conf

hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        resize_on_border = true,

        col = {
            -- Tokyo Night blue (unchanged -- this one was already correct)
            active_border = "rgba(7aa2f7aa)",
            -- Was Catppuccin's "overlay0" grey (rgb(6c7086)) -- swapped for
            -- Tokyo Night's own muted blue-grey so focused/unfocused
            -- borders read as one palette instead of two different themes.
            inactive_border = "rgba(414868aa)",
        },

        -- NOTE: was "dwindles" in the old config -- a typo for "dwindle".
        -- Hyprland's default layout is dwindle anyway, so this typo was
        -- likely masked (silently falling back to the default), but it's
        -- worth fixing outright since it's meaningless as written.
        layout = "dwindle",
    },

    decoration = {
        rounding       = 6,
        rounding_power = 2,

        active_opacity   = 1,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.1,

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            new_optimizations = true,
        },
    },

    dwindle = {
        -- "pseudotile" no longer exists as a dwindle config key in this
        -- Hyprland version (--verify-config rejects it outright); dropped.
        preserve_split       = true,
        special_scale_factor = 0.8,
    },

    input = {
        kb_layout  = "de",
        kb_options = "grp:alt_shift_toggle",

        repeat_rate  = 50,
        repeat_delay = 300,

        numlock_by_default          = true,
        left_handed                 = false,
        follow_mouse                = 1,
        float_switch_override_focus = false,
        sensitivity                 = 0.6,

        touchpad = {
            disable_while_typing   = true,
            natural_scroll         = false,
            clickfinger_behavior   = false,
            middle_button_emulation = true,
            tap_to_click            = true,
            drag_lock                = false,
        },
    },

    cursor = {
        enable_hyprcursor = true, -- was a bogus `env = enable_hyprcursor, 1` before; that line was never a real env var and never took effect
        no_warps          = false, -- was a bogus `env = no_cursor_warps = 0` before, same story
        hide_on_touch      = true, -- was nested as `env = hide_on_touch,1` inside input.touchpad in the old config, which also never worked
    },

    gestures = {
        workspace_swipe_distance             = 400,
        workspace_swipe_invert               = true,
        workspace_swipe_min_speed_to_force   = 30,
        workspace_swipe_cancel_ratio         = 0.5,
        workspace_swipe_create_new           = true,
        workspace_swipe_forever              = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        vrr                      = true,
        enable_swallow           = true,
        focus_on_activate        = false,
        swallow_regex            = "^(kitty)$",
    },

    debug = {
        -- "vfr" (variable frame rate / only render on change) moved from
        -- the old `misc` namespace to `debug` in this Hyprland version.
        vfr           = true,
        disable_logs  = false, -- was a bogus `env = debug:disable_logs = false` line before; never actually took effect as an env var
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    xwayland = {
        -- Helps with scaling/pixelation on fractional-scale setups
        force_zero_scaling = true,
    },
})

-- Touchscreen / 3-finger swipe workspace gesture
-- (the old `gestures { workspace_swipe = 1; workspace_swipe_fingers = 3 }`
-- pair is now expressed as its own declarative gesture, with the knobs
-- above only fine-tuning it)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

------------------------
---- ANIMATIONS ----
------------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("myBezier",  { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("linear",    { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("winIn",     { type = "bezier", points = { {0.1, 1.1},   {0.1, 1.1}   } })
hl.curve("winOut",    { type = "bezier", points = { {0.3, -0.3},  {0, 1}       } })
hl.curve("slow",      { type = "bezier", points = { {0, 0.85},    {0.3, 1}     } })
hl.curve("overshot",  { type = "bezier", points = { {0.7, 0.6},   {0.1, 1.1}   } })
hl.curve("bounce",    { type = "bezier", points = { {1.1, 1.6},   {0.1, 0.85}  } })
-- unused by any animation below (also true in the old config), kept for
-- parity in case you want to reach for it; "sligshot" typo fixed to
-- "slingshot" since nothing referenced the misspelled name anyway
hl.curve("slingshot", { type = "bezier", points = { {1, -1},      {0.15, 1.25} } })
-- The old config also defined a "nice" curve: bezier(0, 6.9, 0.5, -4.20).
-- It was never used by any animation either, and this Hyprland version
-- rejects it outright (control-point Y values are capped at 2.0, this one
-- was 6.9) -- dropped rather than clamped to something meaningless.

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5,   bezier = "slow",    style = "popin" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,   bezier = "winOut",  style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,   bezier = "wind",    style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 10,  bezier = "linear" })
-- old speed was 180 (old engine allowed >100 for a very slow rotation);
-- this version caps animation speed at 100, so 100 is the closest we can
-- get to the original "as slow as possible" rotating-border effect
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear",  style = "loop" })
hl.animation({ leaf = "fade",        enabled = true, speed = 5,   bezier = "overshot" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,   bezier = "wind" })
hl.animation({ leaf = "windows",     enabled = true, speed = 5,   bezier = "bounce",  style = "popin" })
