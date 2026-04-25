#!/usr/bin/env bash
# Swayidle for Fedora Atomic Sway:
# - Timeout 5min  -> swaylock
# - Timeout 10min -> turn outputs off via swaymsg
# - before-sleep  -> trigger the swayidle lock handler
# - lock handler  -> swaylock, guarded against duplicate instances
#
# Used by Sway autostart and toggle-idle.sh.

exec swayidle -w \
    timeout 300 'pidof swaylock || swaylock -f' \
    timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    lock 'pidof swaylock || swaylock -f' \
    before-sleep 'loginctl lock-session' \
    after-resume 'swaymsg "output * power on"'
