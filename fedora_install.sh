#!/usr/bin/env bash
set -euo pipefail

# Fedora Atomic bootstrap: Flatpaks + host essentials + Toolbox + Stow
# - GUI apps via Flatpak (Flathub)
# - Host pkgs via rpm-ostree (git, stow, toolbox, curl, unzip, ripgrep, etc.)
# - Dev pkgs inside toolbox (dnf)
#
# Usage:
#   ./install-fedora-atomic.sh
#
# Notes:
# - If host packages are staged via rpm-ostree, a reboot is required. Script exits and must be re-run after reboot.

REPO_DIR="${REPO_DIR:-$HOME/dotfiles}"          # path to your stow repo clone
TOOLBOX_NAME="${TOOLBOX_NAME:-web}"            # toolbox container name
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

stage_host_pkgs() {
  # Stage host packages; if anything is newly staged, return 10 to signal reboot needed.
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
  log "Installing dev packages in toolbox '$name': $*"
  toolbox run -c "$name" sudo dnf install -y "$@"
}

install_vscode_extensions() {
  if [[ ! -f "$EXT_FILE" ]]; then
    err "Extensions file not found: $EXT_FILE"
    return 1
  fi
  if ! flatpak info com.visualstudio.code >/dev/null 2>&1; then
    err "VS Code Flatpak not installed (com.visualstudio.code)."
    return 1
  fi

  log "Installing VS Code extensions from: $EXT_FILE"
  while read -r ext; do
    [[ -z "$ext" ]] && continue
    log "  - $ext"
    flatpak run com.visualstudio.code --install-extension "$ext" --force
  done <"$EXT_FILE"
}

apply_stow() {
  need_cmd stow
  if [[ ! -d "$REPO_DIR" ]]; then
    err "Dotfiles repo not found at: $REPO_DIR"
    err "Set REPO_DIR env var or clone your repo there."
    return 1
  fi

  log "Running stow in $REPO_DIR"
  cd "$REPO_DIR"

  for d in */; do
    pkg="${d%/}"
    [[ "$pkg" == ".git" ]] && continue
    [[ "$pkg" == "install" || "$pkg" == "scripts" ]] && true
    log "Stowing: $pkg"
    stow -v -t "$HOME" "$pkg" || log "stow failed for $pkg (skipping)"
  done
}

main() {
  if ! is_atomic; then
    err "This script is intended for Fedora Atomic (ostree/rpm-ostree)."
    exit 1
  fi

  log "Fedora Atomic detected"

  if confirm "rpm-ostree upgrade (stage updates)?"; then
    sudo rpm-ostree upgrade
    log "Upgrade staged. Reboot may be required."
  fi

  # Host essentials: keep minimal
  # - git/stow for dotfiles
  # - toolbox for dev env
  # - curl/unzip for common installers/fonts
  # - ripgrep/jq as useful CLI tools
  if confirm "Install host essentials (git, stow, toolbox, curl, unzip, ripgrep, jq)?"; then
    set +e
    stage_host_pkgs git stow toolbox curl unzip ripgrep jq
    rc=$?
    set -e
    if [[ "$rc" == "10" ]]; then
      err "Host packages staged. Reboot now, then re-run this script."
      exit 0
    fi
  fi

  if confirm "Configure Flathub and install GUI apps (Bitwarden/Firefox/Vivaldi/Kitty/VS Code)?"; then
    ensure_flathub
    flatpak_install com.bitwarden.desktop
    flatpak_install org.mozilla.firefox
    flatpak_install com.vivaldi.Vivaldi
    flatpak_install net.kovidgoyal.kitty
    flatpak_install com.visualstudio.code
  fi

  if confirm "Install VS Code extensions from $EXT_FILE ?"; then
    install_vscode_extensions || true
  fi

  if confirm "Create toolbox '$TOOLBOX_NAME' and install web-dev packages inside?"; then
    toolbox_ensure "$TOOLBOX_NAME"
    toolbox_dnf_install "$TOOLBOX_NAME" \
      git ca-certificates curl wget \
      nodejs npm \
      python3 python3-pip \
      podman podman-compose \
      make gcc gcc-c++ \
      openssl openssl-devel \
      sqlite sqlite-devel
  fi

  if confirm "Run stow from $REPO_DIR to link dotfiles into \$HOME?"; then
    apply_stow || true
  fi

  log "Done."
}

main "$@"
