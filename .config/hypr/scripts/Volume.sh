#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Volume / mic control for the XF86Audio* keybinds and waybar's middle-click.
#
# Rewritten 2026-09-16: the original ran pamixer six times per volume step
# (get-mute, change, then get-volume three more times for the notification
# and icon) -- ~40 ms CPU and 65 ms latency per tick. pamixer applies all
# of its flags in one invocation, so "-u -i 5 --get-volume --get-mute"
# unmutes, steps, and reports in a single ~5 ms call; the notification is
# built from that output. Same interface as before:
#   --get --inc --dec --toggle --get-icon
#   --mic-inc --mic-dec --toggle-mic --get-mic-icon
# waybar's pulseaudio scroll no longer calls this (it scrolls in-process).

iDIR="$HOME/.config/swaync/icons"
STEP=5

# icon for a sink volume (empty arg = current)
icon_for() {
    local v=$1
    if   [[ $v == Muted || $v -eq 0 ]]; then echo "$iDIR/volume-mute.png"
    elif (( v <= 30 )); then echo "$iDIR/volume-low.png"
    elif (( v <= 60 )); then echo "$iDIR/volume-mid.png"
    else                     echo "$iDIR/volume-high.png"; fi
}

# run pamixer with the given flags plus --get-volume --get-mute; sets $vol $muted
query() {
    local out
    out=$(pamixer "$@" --get-volume --get-mute 2>/dev/null) || out="0 true"
    # output is "<mute>\n<volume>" or "<mute> <volume>" depending on version
    read -r a b <<< "${out//$'\n'/ }"
    if [[ $a == true || $a == false ]]; then muted=$a; vol=$b; else muted=$b; vol=$a; fi
    vol=${vol:-0}
}

notify_vol() {
    if [[ $muted == true || $vol -eq 0 ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(icon_for Muted)" "Volume: Muted"
    else
        notify-send -e -h int:value:"$vol" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(icon_for "$vol")" "Volume: $vol%"
    fi
}

notify_mic() {
    if [[ $muted == true || $vol -eq 0 ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$iDIR/microphone-mute.png" "Mic-Level: Muted"
    else
        notify-send -e -h int:value:"$vol" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$iDIR/microphone.png" "Mic-Level: $vol%"
    fi
}

case "$1" in
    --inc)        query -u -i $STEP;                   notify_vol ;;
    --dec)        query -u -d $STEP;                   notify_vol ;;
    --toggle)     query -t
                  if [[ $muted == true ]]; then
                      notify-send -e -u low -i "$iDIR/volume-mute.png" "Volume Switched OFF"
                  else
                      notify-send -e -u low -i "$(icon_for "$vol")" "Volume Switched ON"
                  fi ;;
    --mic-inc)    query --default-source -u -i $STEP;  notify_mic ;;
    --mic-dec)    query --default-source -u -d $STEP;  notify_mic ;;
    --toggle-mic) query --default-source -t
                  if [[ $muted == true ]]; then
                      notify-send -e -u low -i "$iDIR/microphone-mute.png" "Microphone Switched OFF"
                  else
                      notify-send -e -u low -i "$iDIR/microphone.png" "Microphone Switched ON"
                  fi ;;
    --get-icon)   query; icon_for "$( [[ $muted == true ]] && echo Muted || echo "$vol" )" ;;
    --get-mic-icon)
                  query --default-source
                  if [[ $muted == true || $vol -eq 0 ]]; then echo "$iDIR/microphone-mute.png"; else echo "$iDIR/microphone.png"; fi ;;
    --get|*)      query; if [[ $muted == true || $vol -eq 0 ]]; then echo Muted; else echo "$vol%"; fi ;;
esac
