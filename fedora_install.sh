#!/usr/bin/env bash
set -euo pipefail

# Fedora Atomic bootstrap
# - Host (rpm-ostree): git, stow, toolbox, kitty, curl, unzip, jq, ripgrep
# - GUI apps (Flatpak): Bitwarden, Firefox, Vivaldi, VS Code
# - Dev env: Toolbox
# - Dotfiles: stow
#
# Re-run after reboot if rpm-ostree stages packages.

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

  local exclude_regex='^(\.git|\.github|scripts?|docs?|install)$'

  for d in */; do
    pkg="${d%/}"
    [[ "$pkg" =~ $exclude_regex ]] && continue
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

  # Host essentials (kitty INCLUDED here)
  if confirm "Install host essentials (git, stow, toolbox, kitty, curl, unzip, jq, ripgrep)?"; then
    set +e
    stage_host_pkgs git stow toolbox kitty curl unzip jq ripgrep
    rc=$?
    set -e
    if [[ "$rc" == "10" ]]; then
      err "Host packages staged. Reboot now and re-run the script."
      exit 0
    fi
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
