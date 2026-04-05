#!/bin/bash

# Notification ID fijo para reemplazar la notificación anterior
NOTIF_ID=9992

action="$1"

case "$action" in
    up)
        brightnessctl -n2 set 5%+
        ;;
    down)
        brightnessctl -n2 set 5%-
        ;;
esac

# Leer brillo actual
BRIGHTNESS=$(brightnessctl get)
MAX=$(brightnessctl max)
PCT=$(( BRIGHTNESS * 100 / MAX ))

if [ "$PCT" -ge 67 ]; then
    ICON="󰃠"
elif [ "$PCT" -ge 34 ]; then
    ICON="󰃟"
else
    ICON="󰃞"
fi

dunstify -a "brightness" -u low -r "$NOTIF_ID" \
    -h "int:value:$PCT" \
    "$ICON  Brillo" "${PCT}%"
