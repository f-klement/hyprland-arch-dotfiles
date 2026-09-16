# Waybar redesign proposals (2026-09-16)

**Adopted: 1 — Solid** (same day). `waybar/config` is `1-solid/config`, and
both theme stylesheets are built from `1-solid/body.css` with only the
palette header swapped: `_common.css` (Rose Pine) → `style/Rose Pine.css`,
`_tokyo.css` (Tokyo Night mapped onto the same role names) →
`style/Tokyo-Night.css`. So `DarkLight.sh` keeps working unchanged. To tweak
the look, edit `body.css` and rebuild both:

    cat _common.css 1-solid/body.css _tail.css > "../style/Rose Pine.css"
    cat _tokyo.css  1-solid/body.css _tail.css >  ../style/Tokyo-Night.css

The pre-redesign files are in `_backup/`.

Workspace numerals: each button hugs its glyphs with 5px either side (even
*gaps*; a fixed-width slot was tried and rejected because the gaps around
"I" came out wider than around "III"), and the font is an absolute 13px --
a percentage font-size resolved differently from one launch to the next.
Note that waybar's style hot-reload can leave rules from the previous
stylesheet in effect when the new one changes a *layout* property; the two
theme files share one body so a theme switch never hits that, but after
editing `body.css` restart waybar once to see the true result.

## Rosé Pine Dawn adopted as the third theme (2026-09-16)

`style/Rose Pine Dawn.css` = `light/_rose-pine-dawn.css` header + the Solid
body. `hypr/scripts/DarkLight.sh` now rotates Tokyo Night → Rosé Pine Moon →
Rosé Pine Dawn; everything per-theme lives in `hypr/themes/<name>/`.
`_common.css` (the "rose-pine" state) was moved from the Rosé Pine *main*
palette to *Moon*, matching kitty/GTK/Kvantum/kdeglobals for that identity.

## Light theme drafts (`light/`)

Six palette headers for a third toggle state, each built onto the same
Solid body: `light/_<name>.css` (header) → `light/<name>.css` (full file).
tokyo-day, rose-pine-dawn, catppuccin-latte, gruvbox-light,
everforest-light, solarized-light. Only Tokyo Day has matching desktop
assets installed (GTK Tokyonight-Light-B-LB, icons Tokyonight-Light,
Kvantum Tokyo-Day, qt5ct Tokyo-Day.conf, rofi tokyo-day.rasi); it still
lacks a kitty theme, a gtk-4.0 accent file, a Plasma colour scheme and a
Thunderbird userChrome before `DarkLight.sh` can rotate to it as a full
identity.

Five redesigns of the current bar. Every module currently on the bar is kept
in every proposal (workspaces, taskbar, weather, launcher, idle inhibitor,
clock, dark/light switch, lock, notifications, tray, mpris, bluetooth,
battery, audio, power, and the dot-line separators). All of them use the
Rose Pine palette so they match the rest of the desktop; each is a
`config` + `style.css` pair that includes the shared `modules` file
unchanged, so every click/scroll binding stays as it is.

| # | Name        | Position | Height | What changes                                                                 |
|---|-------------|----------|--------|------------------------------------------------------------------------------|
| 1 | Solid       | top      | 28     | One edge-to-edge panel, no islands, no rounded corners; underline markers    |
| 2 | Archipelago | top      | 30     | Three blocks split into eight bordered islands; launcher/lock/power tinted   |
| 3 | Semantic    | top      | 28     | Same layout, outlined blocks; every module has a fixed accent, state = colour |
| 4 | Quiet       | top      | 24     | Low-contrast 24px strip, regular weight, no boxes; only state gets colour    |
| 5 | Dock        | bottom   | 34     | Bottom bar; centre dock = launcher+workspaces+apps, corners = time / status  |

`preview.png` in each folder is a real render (a second waybar instance on
the bottom edge of eDP-1, made with `preview.sh`); `current.png` is the bar
as it was when these were written.

## Applying one

The theme toggle (`hypr/scripts/DarkLight.sh`) copies `style/Rose Pine.css`
over `style.css`, so to adopt a proposal permanently:

    cp proposals/N-name/config  ~/.config/waybar/config
    cp proposals/N-name/style.css "~/.config/waybar/style/Rose Pine.css"
    cp proposals/N-name/style.css  ~/.config/waybar/style.css   # takes effect immediately
    # then restart waybar once for the config (layout) half

A Tokyo Night counterpart of the chosen stylesheet still needs to be written
for the light/dark toggle to look consistent in both modes.

## Try one live without committing

    ./preview.sh proposals/N-name /tmp/out.png     # renders it on the bottom edge for ~3s
