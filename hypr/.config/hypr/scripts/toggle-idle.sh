#!/bin/bash

INHIBIT_PID_FILE="/tmp/idle-inhibit.pid"

if systemctl --user is-active --quiet hypridle; then
    systemctl --user stop hypridle
    systemd-inhibit --what=sleep:idle --who="toggle-idle" --why="Idle inhibited by user" --mode=block sleep infinity &
    echo $! > "$INHIBIT_PID_FILE"
    notify-send -i display "Idle disabled" "Screen and sleep inhibited"
else
    systemctl --user start hypridle
    if [ -f "$INHIBIT_PID_FILE" ]; then
        kill "$(cat "$INHIBIT_PID_FILE")" 2>/dev/null
        rm -f "$INHIBIT_PID_FILE"
    fi
    notify-send -i display "Idle enabled" "Auto sleep restored"
fi
