#!/bin/bash
# Controls audio volume and mic mute via swayosd-client / pactl.
# Usage: volume.sh <up|down|mute|mute-mic>
#   up/down    — speaker volume ±5% (capped at 100%)
#   mute       — toggle speaker mute
#   mute-mic   — toggle default microphone mute

action="$1"

case "$action" in
    up)       swayosd-client --output-volume +5 --max-volume 100 ;;
    down)     swayosd-client --output-volume -5 ;;
    mute)     swayosd-client --output-volume mute-toggle ;;
    mute-mic) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
esac
