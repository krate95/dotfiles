#!/bin/bash

INHIBIT_PID_FILE="/tmp/idle-inhibit.pid"

if systemctl --user is-active --quiet hypridle; then
    systemctl --user stop hypridle
    systemd-inhibit --what=sleep:idle --who="toggle-idle" --why="Idle inhibido por el usuario" --mode=block sleep infinity &
    echo $! > "$INHIBIT_PID_FILE"
    notify-send -i display "Idle desactivado" "Pantalla y sleep inhibidos"
else
    systemctl --user start hypridle
    if [ -f "$INHIBIT_PID_FILE" ]; then
        kill "$(cat "$INHIBIT_PID_FILE")" 2>/dev/null
        rm -f "$INHIBIT_PID_FILE"
    fi
    notify-send -i display "Idle activado" "Apagado automático restaurado"
fi
