#!/usr/bin/env bash
# Lanza swayidle con la configuración equivalente a hypridle:
#   - Bloqueo a los 5 min con swaylock
#   - DPMS off a los 10 min
#   - Bloqueo en loginctl lock-session y antes de suspender
# Usado tanto por el autostart de sway como por toggle-idle.sh.

exec swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    lock 'swaylock -f' \
    before-sleep 'loginctl lock-session' \
    after-resume 'swaymsg "output * power on"'
