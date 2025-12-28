#!/usr/bin/env bash
set -e

LAYOUT="t490s"
BASE="$HOME/dotfiles/kde-layouts/$LAYOUT"

echo "Restaurando layout KDE: $LAYOUT"

kquitapp5 plasmashell || true

cp "$BASE/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/
cp "$BASE/plasmashellrc" ~/.config/

kstart5 plasmashell

