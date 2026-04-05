#!/bin/bash

if systemctl --user is-active --quiet hypridle; then
    systemctl --user stop hypridle
    notify-send -i display "Idle desactivado" "Pantalla y sleep inhibidos"
else
    systemctl --user start hypridle
    notify-send -i display "Idle activado" "Apagado automático restaurado"
fi
