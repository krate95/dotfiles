#!/usr/bin/env bash
# Lanza swayidle con la configuración de idle/lock para Kubuntu.
# - Timeout 5min  -> loginctl lock-session (dispara el handler 'lock')
# - Timeout 10min -> DPMS off
# - before-sleep  -> loginctl lock-session
# - lock handler  -> kscreenlocker_greet (KDE)
#
# Usado por el autostart de sway y por toggle-idle.sh.

exec swayidle -w \
    timeout 300 'loginctl lock-session' \
    timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    lock '/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet' \
    before-sleep 'loginctl lock-session' \
    after-resume 'swaymsg "output * power on"'
