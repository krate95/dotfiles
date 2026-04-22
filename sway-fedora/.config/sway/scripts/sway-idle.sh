#!/usr/bin/env bash
# Swayidle para Fedora Atomic Sway:
# - Timeout 5min  -> loginctl lock-session (dispara el handler 'lock' = swaylock)
# - Timeout 10min -> apaga outputs vía swaymsg
# - before-sleep  -> swaylock
# - lock handler  -> swaylock
#
# Usado por el autostart de sway y por toggle-idle.sh.

exec swayidle -w \
    timeout 300 'loginctl lock-session' \
    timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    lock 'swaylock -f' \
    before-sleep 'swaylock -f' \
    after-resume 'swaymsg "output * power on"'
