#!/usr/bin/bash

if pidof wlsunset; then
   killall -9 wlsunset
else
   wlsunset -l 48.2 -L 16.3
fi 
