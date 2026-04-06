#!/bin/bash

# Fixed notification ID to replace previous notification
NOTIF_ID=9991

action="$1"

case "$action" in
    up)
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    mute-mic)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        ;;
esac

# Read current state
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')

if [ "$MUTED" -gt 0 ]; then
    ICON="󰝟"
    MSG="Muted"
    dunstify -a "volume" -u low -r "$NOTIF_ID" \
        -h "int:value:$VOL" \
        "$ICON  Volume" "$MSG" &
else
    if [ "$VOL" -ge 67 ]; then
        ICON="󰕾"
    elif [ "$VOL" -ge 34 ]; then
        ICON="󰖀"
    else
        ICON="󰕿"
    fi
    dunstify -a "volume" -u low -r "$NOTIF_ID" \
        -h "int:value:$VOL" \
        "$ICON  Volume" "${VOL}%" &
fi
