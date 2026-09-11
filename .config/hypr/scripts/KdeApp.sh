#!/bin/bash
## Launch a KDE Frameworks app (Dolphin, Ark, Gwenview, Okular, ...) with
## the native "kde" Qt platform theme instead of the session-wide
## QT_QPA_PLATFORMTHEME=qt6ct (set in env.lua).
##
## WHY (2026-09-11): Dolphin's file list was rendering with an unstyled
## light-gray row background (alternating with a near-black one from a
## different color role) despite kdeglobals having correct Rose Pine/Tokyo
## Night colors and Kvantum's kvconfig also being correct -- neither was
## actually reaching the view. Root cause: KDE Frameworks widgets like
## Dolphin's KItemListView read colors via KColorScheme, which is served
## properly by the native KDEPlasmaPlatformTheme6 platform theme plugin
## (package: plasma-integration) -- qt6ct is a solid *generic* Qt platform
## theme (and still the session default for everything else) but doesn't
## fully replicate that KColorScheme integration, so some KDE-specific
## widgets fell back to Qt defaults for individual color roles while others
## picked up the right values. Confirmed by screenshot + pixel sampling:
## QT_QPA_PLATFORMTHEME=kde alone fixed the color, but dropped Kvantum too
## (kdeglobals had no [KDE] widgetStyle= set, so it fell back to Breeze) --
## DarkLight.sh now sets that key alongside the color scheme so Kvantum's
## SVG theme (with its own real bugs, fixed the same day -- see
## Kvantum/*/​*.kvconfig) still applies on top of the correct KColorScheme.
##
## Same shape as Qt5App.sh's problem (session-wide env var can only serve
## one integration at a time) but for the "kde" vs "qt6ct" platform theme
## rather than Qt5 vs Qt6 -- one wrapper, reusable for any KDE app. Dolphin
## is wired in (see hypr/keybinds.lua's `files` var and
## ~/.local/share/applications/org.kde.dolphin.desktop's override); the
## full kde-applications group installed here (ark, gwenview, okular,
## kcalc, konsole, partitionmanager, ...) likely has the same gap -- wire
## in whichever you actually hit it with, same pattern.
##
## Usage: KdeApp.sh <command> [args...]

exec env QT_QPA_PLATFORMTHEME=kde "$@"
