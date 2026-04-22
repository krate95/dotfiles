#!/bin/bash
# Reads CPU package temperature and outputs JSON for waybar
# Green < 60°C | Yellow 60–79°C | Red >= 80°C

temp_raw=$(cat /sys/class/thermal/thermal_zone6/temp)
temp=$((temp_raw / 1000))

if   [ "$temp" -ge 80 ]; then class="critical"
elif [ "$temp" -ge 60 ]; then class="warning"
else                          class="normal"
fi

echo "{\"text\":\"${temp}󰔄 \",\"class\":\"${class}\",\"tooltip\":\"CPU Package: ${temp}°C\"}"
