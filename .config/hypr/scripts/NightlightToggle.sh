#!/usr/bin/bash
## Toggle the blue-light filter. Was wlsunset (lat/long-based), now
## hyprsunset (fixed time profiles read from ~/.config/hypr/hyprsunset.conf
## -- see that file for the trade-off this swap made).

if pidof hyprsunset > /dev/null; then
   killall -9 hyprsunset
else
   hyprsunset &
   disown
fi
