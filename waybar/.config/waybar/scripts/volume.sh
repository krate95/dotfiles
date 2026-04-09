#!/bin/bash

action="$1"

case "$action" in
    up)       swayosd-client --output-volume +5 --max-volume 100 ;;
    down)     swayosd-client --output-volume -5 ;;
    mute)     swayosd-client --output-volume mute-toggle ;;
    mute-mic) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
esac
