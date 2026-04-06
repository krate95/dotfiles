#!/usr/bin/env bash

set -euo pipefail

mode="${1:-area}"
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
screenshots_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
filename="${screenshots_dir}/Screenshot_${timestamp}.png"

mkdir -p "$screenshots_dir"

case "$mode" in
  area)
    geometry="$(slurp)"
    [ -n "$geometry" ]
    grim -g "$geometry" "$filename"
    ;;
  screen)
    grim "$filename"
    ;;
  *)
    notify-send "Screenshot" "Unsupported mode: $mode"
    exit 1
    ;;
esac

wl-copy < "$filename"
notify-send "Screenshot saved" "$(basename "$filename") copied to clipboard"
