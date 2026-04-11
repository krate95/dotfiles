#!/usr/bin/env bash
# Power menu using wofi

SHUTDOWN="󰐥  Shutdown"
REBOOT="󰜉  Reboot"
SUSPEND="󰒲  Suspend"
LOCK="󰌾  Lock"
LOGOUT="󰍃  Logout"

CHOICE=$(printf '%s\n' "$LOCK" "$SUSPEND" "$LOGOUT" "$REBOOT" "$SHUTDOWN" \
    | wofi --dmenu \
           --prompt "Power" \
           --width 200 \
           --height 240 \
           --lines 5 \
           --no-actions \
           --hide-search \
           --insensitive \
           --normal-window)

case "$CHOICE" in
    "$SHUTDOWN") systemctl poweroff ;;
    "$REBOOT")   systemctl reboot ;;
    "$SUSPEND")  systemctl suspend ;;
    "$LOCK")     hyprlock ;;
    "$LOGOUT")   hyprctl dispatch exit ;;
esac
