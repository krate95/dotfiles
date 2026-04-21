# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow *package* — its internal layout mirrors `$HOME`. Running `stow -t "$HOME" <package>` creates symlinks in `$HOME`.

Supported machines:

| Machine | OS | WM/DE |
|---|---|---|
| Lenovo ThinkPad T490s | Arch Linux | Hyprland |
| Dell Latitude 5520 | Kubuntu | Sway alongside KDE Plasma |
| Mac Mini M1 | macOS | — |

## Common operations

```bash
# Full interactive install (packages + stow)
./install.sh

# Stow a single package manually
stow -t "$HOME" <package>

# Re-stow after adding/moving files in a package
stow -v -R -t "$HOME" <package>

# Install VS Code extensions from the list
while read -r ext; do code --install-extension "$ext"; done < Code/extensions
```

## Package layout and OS targeting

`install.sh` / `apply_stow()` skips packages based on OS:

- **All 3 machines**: `zsh`, `nvim`, `kitty`
- **Arch + Kubuntu** (Linux): `waybar`, `dunst`, `wallpapers`
- **Arch-only** (ThinkPad T490s / Hyprland): `hypr`, `swayosd`, `wob`, `mako`, `kanata`
- **Kubuntu-only** (Dell Latitude 5520 / KDE Plasma): `kanshi` — `sway` exists in the repo but is not currently in use
- **macOS-only** (Mac Mini M1): `Code-macos` (VS Code settings live under `Library/Application Support`)
- **Linux VS Code**: `Code` (uses `.config/Code/` path)
- **`/etc/` configs** (copied, not stowed — Arch only): `thinkfan`, `tlp`, `intel-undervolt.conf`
- **Not stowed**: `kde-layouts`, `sddm-theme`

## Key configs

### Neovim (`nvim/`)

Entry point: `nvim/.config/nvim/init.lua` → loads `lua/krate/` module.

```
lua/krate/
  init.lua        # sets mapleader=" ", requires lazy_init
  lazy_init.lua   # bootstraps lazy.nvim, loads spec from krate.lazy
  lsp_keymaps.lua # shared LSP keymap setup
  lazy/           # one file per plugin (autopairs, lsp, telescope, treesitter, …)
```

`lazy-lock.json` tracks pinned plugin versions — commit it when updating plugins.

### Waybar (`waybar/`)

Two style variants sharing a single script directory:

- `config` + `style.css` — Hyprland (Arch)
- `config-sway` + `style-sway.css` + `mocha.css` — Sway (Kubuntu)

Custom shell scripts in `scripts/`: `brightness.sh`, `volume.sh`, `temperature.sh`, `power-mode.sh`, `wofi-bluetooth`.

### Sway (`sway/`)

Output management is **delegated to kanshi** (not configured in `sway/config`). kanshi config is at `kanshi/.config/kanshi/config`.

Sway launches waybar with the `-c ~/.config/waybar/config-sway` flag to use the Sway-specific variant.

### Kanata (`kanata/`)

Keyboard remapping for the ThinkPad T490s. `install.sh` creates a systemd drop-in at `/etc/systemd/system/kanata.service.d/override.conf` pointing to the stowed config at `~/.config/kanata/kanata.kbd`. Requires the user to be in the `input` and `uinput` groups.

## Theme

Catppuccin Mocha throughout: kitty terminal, Neovim, waybar CSS, SDDM login screen.
