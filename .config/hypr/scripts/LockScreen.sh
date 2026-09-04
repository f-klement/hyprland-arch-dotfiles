#!/bin/bash
## For hyprlock (was swaylock-effects)

# hyprlock reads ~/.config/hypr/hyprlock.conf automatically, no --config
# flag needed (unlike swaylock).
pidof hyprlock || { sleep 0.5s; hyprlock & disown; }
