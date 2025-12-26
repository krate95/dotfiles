#!/usr/bin/env bash
set -e

EXT_FILE="$HOME/dotfiles/Code/extensions"

if ! command -v code >/dev/null 2>&1; then
  echo "Missing VS Code"
  exit 1
fi

if [ ! -f "$EXT_FILE" ]; then
  echo "Missing extension file $EXT_FILE"
  exit 1
fi

while read -r ext; do
  [ -z "$ext" ] && continue
  echo "Installing $ext"
  code --install-extension "$ext" --force
done < "$EXT_FILE"
