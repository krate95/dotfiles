#!/bin/bash

action="$1"

case "$action" in
    up)   swayosd-client --brightness +5 ;;
    down) swayosd-client --brightness -5 ;;
esac
