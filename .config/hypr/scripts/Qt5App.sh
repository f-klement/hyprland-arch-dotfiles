#!/bin/bash
# Launch a Qt5 app with Qt5's own theme integration (qt5ct), instead of the
# session-wide QT_QPA_PLATFORMTHEME=qt6ct (set in env.lua).
#
# Why this has to be a wrapper and can't just be another env var: Qt5 apps
# and Qt6 apps each search their OWN Qt-major-versioned plugin directory
# for a platformtheme plugin matching QT_QPA_PLATFORMTHEME
# (/usr/lib/qt/plugins/platformthemes for Qt5, /usr/lib/qt6/plugins/
# platformthemes for Qt6) -- there's no list/fallback syntax for this
# variable (unlike QT_QPA_PLATFORM's "wayland;xcb"), so one global value
# can only ever satisfy one Qt major version at a time.
#
# qt5ct is already fully configured to match: color_scheme_path points at
# ~/.config/qt5ct/colors/Tokyo-Night.conf, icon_theme=Tokyonight-Dark. The
# one difference from the Qt6 side is `style=Fusion` rather than Kvantum --
# the Qt5 Kvantum engine package conflicts with kvantum-qt6-git, which is
# what's actually installed, so Qt5 apps get the right colors/icons via
# qt5ct but the built-in Fusion widget style rather than true Kvantum
# theming. Install the (non-git) `kvantum` package instead of
# kvantum-qt6-git if you want pixel-identical Kvantum styling on both --
# they conflict, so that's a swap, not an addition.
#
# Usage: Qt5App.sh <command> [args...]
# e.g. as a keybind: hl.dsp.exec_cmd(scriptsDir .. "/Qt5App.sh someqt5app")

exec env QT_QPA_PLATFORMTHEME=qt5ct "$@"
