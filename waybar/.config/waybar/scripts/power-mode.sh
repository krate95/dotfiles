#!/bin/bash

# Read AC online status from sysfs
AC_ONLINE=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)

if [ "$AC_ONLINE" = "1" ]; then
    echo '{"text":"󱐋 AC","class":"ac","tooltip":"TLP: performance mode"}'
else
    echo '{"text":"󰁹 BAT","class":"bat","tooltip":"TLP: battery save mode"}'
fi
