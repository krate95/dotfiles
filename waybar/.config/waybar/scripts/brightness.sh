#!/bin/bash
# Adjusts screen brightness via swayosd-client.
# Usage: brightness.sh <up|down>  — changes brightness by 5% steps.

action="$1"

case "$action" in
    up)   swayosd-client --brightness +5 ;;
    down) swayosd-client --brightness -5 ;;
esac
