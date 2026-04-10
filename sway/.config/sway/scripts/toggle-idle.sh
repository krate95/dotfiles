#!/usr/bin/env bash
# Toggles idle inhibition: mata swayidle y bloquea sleep/idle via systemd-inhibit,
# o relanza swayidle y elimina el inhibidor. Envía una notificación en cada cambio.

INHIBIT_PID_FILE="/tmp/idle-inhibit.pid"

if pgrep -u "$USER" -x swayidle >/dev/null; then
    pkill -u "$USER" -x swayidle
    systemd-inhibit --what=sleep:idle --who="toggle-idle" --why="Idle inhibited by user" --mode=block sleep infinity &
    echo $! > "$INHIBIT_PID_FILE"
    notify-send -i display "Idle disabled" "Screen and sleep inhibited"
else
    "$HOME/.config/sway/scripts/sway-idle.sh" &
    disown
    if [ -f "$INHIBIT_PID_FILE" ]; then
        kill "$(cat "$INHIBIT_PID_FILE")" 2>/dev/null
        rm -f "$INHIBIT_PID_FILE"
    fi
    notify-send -i display "Idle enabled" "Auto sleep restored"
fi
