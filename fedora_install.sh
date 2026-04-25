#!/usr/bin/env bash
set -euo pipefail

# Fedora Atomic Sway dotfiles bootstrap
# Requires: Fedora Atomic (Sway spin o variante equivalente) con rpm-ostree.
# Re-run after reboot if packages are staged.
#
# Overlays de rpm-ostree se mantienen al mínimo: la imagen base de Sway
# Atomic ya trae sway/swaybg/swaylock/swayidle, waybar, wofi, mako, grim,
# slurp, wl-clipboard, NetworkManager, toolbox, flatpak, git, curl, unzip,
# etc. Solo se layeriza lo que falta o lo que reemplaza un default de base
# (kitty en vez de foot, dunst en vez de mako).
#
# Each step is opt-in (interactive y/N prompt). Installs:
#   - rpm-ostree upgrade            — stage system update (reboot may be required)
#   Host layer (rpm-ostree overlay):
#     stow, kitty, zsh, fprintd, ripgrep, jq
#   Sway stack (rpm-ostree overlay):
#     dunst, thunar, polkit-gnome, network-manager-applet
#     (swayosd vía COPR erikreider/SwayOSD — opcional)
#   Fonts:
#     Cascadia Code Nerd Font       — installed to ~/.local/share/fonts
#   Shell:
#     Oh My Zsh                     — plugins: zsh-autosuggestions, zsh-syntax-highlighting
#     Oh My Posh                    — prompt theme engine, installed to ~/.local/bin
#   GUI apps (Flatpak via Flathub):
#     Bitwarden, Firefox, Vivaldi, VS Code
#   VS Code extensions              — read from Code/extensions
#   Toolbox (container 'web'):
#     git, curl, wget, nodejs, npm, python3, pip, jq, ripgrep, make, gcc, openssl
#   Dotfiles:
#     stow                          — symlinks relevant packages into $HOME

REPO_DIR="${REPO_DIR:-$HOME/dotfiles}"
TOOLBOX_NAME="${TOOLBOX_NAME:-web}"
EXT_FILE="${EXT_FILE:-$REPO_DIR/Code/extensions}"

log() { echo "[atomic] $*"; }
err() { echo "[atomic][ERROR] $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }
}

is_atomic() {
  [[ -e /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1
}

confirm() {
  local prompt="$1"
  local reply
  read -rp "$prompt [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# -------------------------
# Flatpak helpers
# -------------------------
ensure_flathub() {
  need_cmd flatpak
  if flatpak remotes --columns=name 2>/dev/null | grep -qx "flathub"; then
    log "Flathub already configured"
  else
    log "Adding Flathub"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

flatpak_install() {
  local appid="$1"
  if flatpak info "$appid" >/dev/null 2>&1; then
    log "Flatpak already installed: $appid"
  else
    log "Installing Flatpak: $appid"
    flatpak install -y flathub "$appid"
  fi
}

# -------------------------
# rpm-ostree host packages
# -------------------------
stage_host_pkgs() {
  local pkgs=("$@")
  local to_install=()

  for p in "${pkgs[@]}"; do
    if rpm -q "$p" >/dev/null 2>&1; then
      log "Host pkg already installed: $p"
    else
      to_install+=("$p")
    fi
  done

  if (( ${#to_install[@]} > 0 )); then
    log "Staging host packages via rpm-ostree: ${to_install[*]}"
    sudo rpm-ostree install "${to_install[@]}"
    return 10
  fi

  return 0
}

# -------------------------
# Sway stack (rpm-ostree)
# -------------------------
install_sway_stack() {
  # Overlays mínimos: sway/swaybg/swaylock/swayidle, waybar, wofi, grim,
  # slurp, wl-clipboard, playerctl, brightnessctl, mako, gnome-keyring y
  # NetworkManager ya vienen en la imagen base de Sway Atomic. Solo
  # añadimos:
  #   - dunst                    reemplaza mako (compartimos config con hypr)
  #   - thunar                   file manager ($fileManager en sway/config)
  #   - polkit-gnome             polkit agent para pedir contraseña con GUI
  #   - network-manager-applet   tray/indicador NM (nm-applet --indicator)
  set +e
  stage_host_pkgs dunst thunar polkit-gnome network-manager-applet
  local rc=$?
  set -e

  if [[ "$rc" == "10" ]]; then
    err "Sway packages staged. Reboot now and re-run the script."
    exit 0
  fi
}

# swayosd lives in a COPR (erikreider/SwayOSD). Atomic no expone dnf copr,
# así que usamos el repo .repo directo antes del rpm-ostree install.
install_swayosd() {
  local repo_file="/etc/yum.repos.d/_copr_erikreider-SwayOSD.repo"
  if [[ ! -f "$repo_file" ]]; then
    log "Añadiendo COPR erikreider/SwayOSD"
    local fedora_ver
    fedora_ver="$(rpm -E %fedora)"
    sudo tee "$repo_file" >/dev/null <<EOF
[copr:copr.fedorainfracloud.org:erikreider:SwayOSD]
name=Copr repo for SwayOSD owned by erikreider
baseurl=https://download.copr.fedorainfracloud.org/results/erikreider/SwayOSD/fedora-${fedora_ver}-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/erikreider/SwayOSD/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF
  fi

  set +e
  stage_host_pkgs swayosd
  local rc=$?
  set -e

  if [[ "$rc" == "10" ]]; then
    err "swayosd staged. Reboot now and re-run the script."
    exit 0
  fi
}

# -------------------------
# Toolbox
# -------------------------
toolbox_ensure() {
  local name="$1"
  need_cmd toolbox

  if toolbox list 2>/dev/null | awk '{print $1}' | grep -qx "$name"; then
    log "Toolbox exists: $name"
  else
    log "Creating toolbox: $name"
    toolbox create "$name"
  fi
}

toolbox_dnf_install() {
  local name="$1"; shift
  log "Installing dev packages in toolbox '$name'"
  toolbox run -c "$name" sudo dnf install -y "$@"
}

# -------------------------
# Oh my zsh
# -------------------------
install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return 0
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  mkdir -p "$ZSH_CUSTOM/plugins"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log "Installing zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log "Installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
}

# -------------------------
# Oh my posh
# -------------------------
install_oh_my_posh() {
  local bin_dir="$HOME/.local/bin"
  local omp_bin="$bin_dir/oh-my-posh"

  mkdir -p "$bin_dir"

  if [[ -x "$omp_bin" ]]; then
    log "Oh My Posh already installed at $omp_bin"
    return 0
  fi

  log "Installing Oh My Posh to $bin_dir"
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$bin_dir"

  if [[ ! -x "$omp_bin" ]]; then
    err "Oh My Posh installation failed (missing $omp_bin)"
    return 1
  fi

  # Ensure ~/.local/bin is in PATH for future shells
  local zprofile="$HOME/.zprofile"
  local path_line='export PATH="$HOME/.local/bin:$PATH"'
  if [[ -f "$zprofile" ]] && grep -Fqx "$path_line" "$zprofile"; then
    log "~/.local/bin already in PATH via ~/.zprofile"
  else
    log "Adding ~/.local/bin to PATH in ~/.zprofile"
    printf '\n# User binaries\n%s\n' "$path_line" >> "$zprofile"
  fi
}

# -------------------------
# Fonts
# -------------------------
install_fonts() {
  local font_dir="$HOME/.local/share/fonts"
  local tmpdir
  tmpdir="$(mktemp -d)"

  log "Installing Cascadia Code Nerd Font (user-local)"

  mkdir -p "$font_dir"

  curl -fsSL \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip \
    -o "$tmpdir/CascadiaCode.zip"

  unzip -qo "$tmpdir/CascadiaCode.zip" -d "$font_dir"

  fc-cache -fv "$font_dir"

  rm -rf "$tmpdir"

  log "Cascadia Code Nerd Font installed"
}

# -------------------------
# VS Code extensions
# -------------------------
install_vscode_extensions() {
  if [[ ! -f "$EXT_FILE" ]]; then
    err "Extensions file not found: $EXT_FILE"
    return 1
  fi
  if ! flatpak info com.visualstudio.code >/dev/null 2>&1; then
    err "VS Code Flatpak not installed"
    return 1
  fi

  log "Installing VS Code extensions"
  while IFS= read -r ext; do
    ext="${ext%%#*}"
    ext="$(echo -n "$ext" | xargs)"
    [[ -z "$ext" ]] && continue
    log "  - $ext"
    flatpak run com.visualstudio.code --install-extension "$ext" --force
  done <"$EXT_FILE"
}

# -------------------------
# Stow
# -------------------------
apply_stow() {
  need_cmd stow
  [[ -d "$REPO_DIR" ]] || { err "Dotfiles repo not found: $REPO_DIR"; return 1; }

  log "Running stow in $REPO_DIR"
  cd "$REPO_DIR"

  # Paquetes que no son para Fedora:
  #   - hypr, mako, wob, kanata    → Arch-only (Hyprland stack)
  #   - sway, kanshi               → Kubuntu-only (config para KDE/kscreenlocker)
  #   - thinkfan, tlp              → /etc, gestionados por install.sh (Arch)
  #   - Code-macos                 → macOS-only
  #   - kde-layouts, sddm-theme    → no son dotfiles
  local skip_regex='^(\.git|\.github|hypr|mako|wob|kanata|sway|kanshi|thinkfan|tlp|Code-macos|kde-layouts|sddm-theme)$'

  for d in */; do
    pkg="${d%/}"
    [[ "$pkg" =~ $skip_regex ]] && { log "Skip: $pkg"; continue; }
    log "Stowing: $pkg"
    stow -v --no-folding -t "$HOME" "$pkg" || log "stow failed for $pkg"
  done
}

# -------------------------
# Main
# -------------------------
main() {
  if ! is_atomic; then
    err "This script is for Fedora Atomic only."
    exit 1
  fi

  log "Fedora Atomic detected"

  if confirm "rpm-ostree upgrade (stage system update)?"; then
    sudo rpm-ostree upgrade
    log "Upgrade staged (reboot may be required)."
  fi

  # Host essentials: solo lo que no viene en base. git/curl/unzip/toolbox ya
  # están en la imagen de Sway Atomic.
  if confirm "Install host essentials (stow, kitty, zsh, fprintd, ripgrep, jq)?"; then
    set +e
    stage_host_pkgs stow kitty zsh fprintd ripgrep jq
    rc=$?
    set -e
    if [[ "$rc" == "10" ]]; then
      err "Host packages staged. Reboot now and re-run the script."
      exit 0
    fi
  fi

  if confirm "Install Sway stack overlay (dunst, thunar, polkit-gnome, network-manager-applet)?"; then
    install_sway_stack
  fi

  if confirm "Install swayosd (COPR erikreider/SwayOSD)?"; then
    install_swayosd
  fi

  if confirm "Install fonts?"; then
    install_fonts
  fi

  if confirm "Install Oh My Zsh (user-only)?"; then
    install_oh_my_zsh
  fi

  if confirm "Install Oh My Posh (user-only, ~/.local/bin)?"; then
    install_oh_my_posh || true
  fi

  if confirm "Install GUI apps via Flatpak (Bitwarden, Firefox, Vivaldi, VS Code)?"; then
    ensure_flathub
    flatpak_install com.bitwarden.desktop
    flatpak_install org.mozilla.firefox
    flatpak_install com.vivaldi.Vivaldi
    flatpak_install com.visualstudio.code
  fi

  if confirm "Install VS Code extensions?"; then
    install_vscode_extensions || true
  fi

  if confirm "Create toolbox '$TOOLBOX_NAME' and install web-dev packages?"; then
    toolbox_ensure "$TOOLBOX_NAME"
    toolbox_dnf_install "$TOOLBOX_NAME" \
      git ca-certificates curl wget \
      nodejs npm \
      python3 python3-pip \
      jq ripgrep \
      make gcc gcc-c++ \
      openssl openssl-devel
  fi

  if confirm "Run stow to link dotfiles into \$HOME?"; then
    apply_stow || true
  fi

  log "Done."
}

main "$@"
