# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Supports **Arch Linux**, **Kubuntu**, and **macOS**.

## Machines

| Machine | OS | Notes |
|---|---|---|
| Lenovo ThinkPad T490s | Arch Linux | Hyprland stack; kanata keyboard remapper; intel-undervolt, thinkfan, TLP |
| Dell Latitude 5520 | Kubuntu | Sway alongside KDE Plasma via SDDM |
| Mac Mini M1 | macOS | Homebrew; macOS defaults script |

## Quick start

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is interactive — each step is opt-in. It installs packages and runs `stow` to symlink configs into `$HOME`.

## Packages

| Package | Description | OS |
|---|---|---|
| `zsh` | zsh + Oh My Zsh + autosuggestions + syntax-highlighting + Oh My Posh | all |
| `kitty` | Terminal emulator (Catppuccin Mocha theme, quick-access overlay) | all |
| `nvim` | Neovim config (Lazy.nvim) | all |
| `Code` | VS Code settings and keybindings | Linux |
| `Code-macos` | VS Code settings and keybindings | macOS |
| `hypr` | Hyprland, hypridle, hyprlock, hyprpaper configs | Arch |
| `waybar` | Status bar (shared base + sway variant) | Arch, Kubuntu |
| `dunst` | Notification daemon | Arch, Kubuntu |
| `sway` | Sway config (runs alongside KDE Plasma via SDDM) | Kubuntu |
| `mako` | Notification daemon (legacy, replaced by dunst) | Arch |
| `swayosd` | On-screen display for volume, brightness, caps lock | Arch |
| `wob` | Wayland overlay bar | Arch |
| `kanata` | Keyboard remapper (T490s layout) | Arch |
| `wallpapers` | Wallpaper files | Linux |

### Arch-only system configs (copied to `/etc/`, not stowed)

| File/dir | Description |
|---|---|
| `thinkfan/` | Fan speed control (`/etc/thinkfan.conf`) |
| `tlp/` | Battery management (`/etc/tlp.conf`) |
| `intel-undervolt.conf` | CPU undervolting (`/etc/intel-undervolt.conf`) |
| `sddm-theme/` | Catppuccin Mocha Lavender login screen (`/usr/share/sddm/themes/`) |

## Stow layout

Each package directory mirrors `$HOME`. For example:

```
zsh/.zshrc                       → ~/.zshrc
kitty/.config/kitty/kitty.conf   → ~/.config/kitty/kitty.conf
hypr/.config/hypr/hyprland.conf  → ~/.config/hypr/hyprland.conf
```

To stow a single package manually:

```bash
cd ~/dotfiles
stow -t "$HOME" <package>
```

## Sway on Kubuntu

Sway coexists with KDE Plasma as an SDDM session. It reuses:
- **kscreenlocker** — screen locking (`Super+L`)
- **nm-applet** — NetworkManager tray / secret agent
- **Breeze SDDM theme** — login screen (no custom theme needed)

Select *Sway* from the SDDM session menu to switch.

## Hyprland on Arch

Full Wayland compositor stack:

- **hyprland** — compositor
- **hypridle / hyprlock** — idle and lock
- **hyprpaper** — wallpaper
- **waybar** — status bar with CPU temp, volume, and brightness
- **dunst** — notifications
- **swayosd** — OSD overlays
- **wob** — progress bar overlay
- **kanata** — keyboard remapping (runs as a systemd service)
- **sddm** — display manager (Catppuccin Mocha Lavender theme)

## Extensions

VS Code extensions are listed in `Code/extensions`. To install them:

```bash
while read -r ext; do code --install-extension "$ext"; done < Code/extensions
```

`install.sh` handles this automatically when prompted.
