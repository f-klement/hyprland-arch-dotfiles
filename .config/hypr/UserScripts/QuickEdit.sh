#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

hypr="$HOME/.config/hypr"

# Updated for the Lua config layout (was UserConfigs/*.conf + configs/*.conf)
menu(){
  printf "1. view Env-variables\n"
  printf "2. view Window-Rules\n"
  printf "3. view Autostart\n"
  printf "4. view Keybinds\n"
  printf "5. view Monitors\n"
  printf "6. view Laptop-Keybinds\n"
  printf "7. view Settings (general/decoration/animations/input)\n"
  printf "8. view entry point (hyprland.lua)\n"
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-compact.rasi | cut -d. -f1)
    case $choice in
        1)
            kitty -e nano "$hypr/env.lua"
            ;;
        2)
            kitty -e nano "$hypr/windowrules.lua"
            ;;
        3)
            kitty -e nano "$hypr/autostart.lua"
            ;;
        4)
            kitty -e nano "$hypr/keybinds.lua"
            ;;
        5)
            kitty -e nano "$hypr/monitors.lua"
            ;;
        6)
            kitty -e nano "$hypr/keybinds_laptop.lua"
            ;;
        7)
            kitty -e nano "$hypr/settings.lua"
            ;;
        8)
            kitty -e nano "$hypr/hyprland.lua"
            ;;
        *)
            ;;
    esac
}

main