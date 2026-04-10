#!/usr/bin/env bash
set -euo pipefail

# Multi-OS dotfiles installer
# Supports: Ubuntu/Debian, macOS (Homebrew), and Arch Linux
#
# Each step is opt-in (interactive y/N prompt). Installs:
#   - stow                      — dotfile symlink manager
#   - VS Code + extensions      — editor (Homebrew cask on macOS); extensions read from Code/extensions
#   - kitty                     — terminal emulator (official installer)
#   - Cascadia Code Nerd Font   — programming font
#   - zsh + Oh My Zsh           — shell; plugins: zsh-autosuggestions, zsh-syntax-highlighting
#   - Oh My Posh                — shell prompt theme engine
#   - Neovim + ripgrep          — editor and fast search tool
#   [macOS only]
#   - macOS defaults             — system preferences via macos-defaults.sh (input, Finder,
#                                  Dock, screenshots, Safari, quality-of-life tweaks)
#   [Arch Linux only]
#   - Hyprland stack            — hyprland, waybar, dunst, swayosd, playerctl, brightnessctl,
#                                 hypridle, hyprlock, hyprpaper, grim, slurp, wob, sddm
#   - SDDM theme                — catppuccin-mocha-lavender login screen theme
#   - intel-undervolt (AUR)     — CPU undervolting for ThinkPads
#   - thinkfan                  — fan speed control; config copied to /etc/thinkfan.conf
#   - TLP                       — battery power management; config copied to /etc/tlp.conf
#   - kanata (AUR)              — keyboard remapper; service override points to stowed config

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXT_FILE_DEFAULT="$REPO_DIR/Code/extensions"

install_vscode_extensions() {
	local ext_file="${EXT_FILE:-$EXT_FILE_DEFAULT}"

	if ! command -v code >/dev/null 2>&1; then
		err "Missing VS Code (the 'code' command is not available)"
		return 1
	fi

	if [[ ! -f "$ext_file" ]]; then
		err "Missing extension file $ext_file"
		return 1
	fi

	while read -r ext; do
		[[ -z "$ext" ]] && continue
		log "Installing $ext"
		code --install-extension "$ext" --force
	done <"$ext_file"
}

log() { echo "[install] $*"; }
err() { echo "[install][ERROR] $*" >&2; }

confirm() {
	local prompt="$1"
	local reply
	read -rp "$prompt [y/N]: " reply
	[[ "$reply" =~ ^[Yy]$ ]]
}

detect_os() {
	if [[ "$(uname)" == "Darwin" ]]; then
		echo "macos"
		return
	fi
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian)
				echo "ubuntu"
				return
				;;
			arch|manjaro)
				echo "arch"
				return
				;;
		esac
	fi
	# Fallback
	echo "unknown"
}

install_stow() {
	case "$OS" in
		macos) brew install stow ;;
		ubuntu) sudo apt update && sudo apt install -y stow ;;
		arch) sudo pacman -Sy --noconfirm stow ;;
		*) err "Cannot install stow on $OS"; return 1 ;;
	esac
}

install_vscode() {
	case "$OS" in
		macos)
			brew install --cask visual-studio-code || true
			;;
		ubuntu)
			if ! command -v code >/dev/null 2>&1; then
				log "Installing VS Code..."
				wget https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64 -O vscode.deb
                sudo apt install -y ./vscode.deb || true
                rm vscode.deb
			fi
			;;
		arch)
			yay -Sy --noconfirm visual-studio-code-bin || true
			;;
		*) err "Cannot install VS Code on $OS"; return 1 ;;
	esac
}

install_kitty() {
	curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
}

install_zsh_and_oh_my_zsh() {
	case "$OS" in
		macos)
			brew install zsh || true
			;;
		ubuntu)
			sudo apt-get install -y zsh git curl || true
			;;
		arch)
			sudo pacman -Sy --noconfirm zsh git curl || true
			;;
	esac

	if confirm "Change default shell to zsh?"; then
		chsh -s "$(command -v zsh)" || true
	fi

	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		log "Installing Oh My Zsh"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		log "Oh My Zsh already installed"
	fi

    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    plugins_dir="$ZSH_CUSTOM_DIR/plugins"
    mkdir -p "$plugins_dir"

    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
		log "Cloning zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
    else
		log "zsh-autosuggestions already exists; skipping."
    fi

    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
		log "Cloning zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
    else
		log "zsh-syntax-highlighting already exists; skipping."
    fi
}

install_oh_my_posh() {
    case "$OS" in
        macos)
            brew install oh-my-posh || true
            ;;
        ubuntu)
            curl -s https://ohmyposh.dev/install.sh | bash -s
            ;;
        arch)
            curl -s https://ohmyposh.dev/install.sh | bash -s
            ;;
    esac
}

install_cascadia_code_nerd_font() {
    case "$OS" in
        macos)
            brew install --cask font-caskaydia-cove-nerd-font || true
            ;;
        arch)
            sudo pacman -Sy --noconfirm ttf-cascadia-code-nerd || true
            ;;
        ubuntu)
            local tmpdir
            tmpdir="$(mktemp -d)"
            local url
            url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
            local archive
            archive="$tmpdir/CascadiaCode.zip"
            log "Downloading Cascadia Code Nerd Font..."
            curl -fL "$url" -o "$archive"
            local font_dir="$HOME/.local/share/fonts"
            mkdir -p "$font_dir"
            log "Extracting Cascadia Code Nerd Font to $font_dir..."
            unzip -q "$archive" -d "$font_dir"
            fc-cache -fv
            rm -rf "$tmpdir"
            ;;
    esac
}

install_hypr_packages() {
	if [[ "$OS" != "arch" ]]; then
		err "Hyprland packages are only supported on Arch Linux"
		return 1
	fi

	# Core Hyprland stack
	sudo pacman -Sy --noconfirm \
		hyprland hyprlock hypridle hyprpaper \
		waybar \
		dunst \
		playerctl brightnessctl \
		grim slurp \
		wob \
		sddm || true

	# swayosd is in AUR
	if command -v yay >/dev/null 2>&1; then
		yay -Sy --noconfirm swayosd || true
	else
		log "yay not found, skipping swayosd (AUR package)"
	fi
}

install_thinkfan() {
	if [[ "$OS" != "arch" ]]; then
		err "thinkfan is only supported on Arch Linux"
		return 1
	fi

	sudo pacman -Sy --noconfirm thinkfan || true

	local conf_src="$REPO_DIR/thinkfan/thinkfan.conf"
	if [[ -f "$conf_src" ]]; then
		log "Copying thinkfan.conf to /etc/thinkfan.conf"
		sudo cp "$conf_src" /etc/thinkfan.conf
		sudo systemctl enable thinkfan || true
	fi
}

install_tlp() {
	if [[ "$OS" != "arch" ]]; then
		err "TLP is only supported on Arch Linux"
		return 1
	fi

	sudo pacman -Sy --noconfirm tlp || true

	local conf_src="$REPO_DIR/tlp/tlp.conf"
	if [[ -f "$conf_src" ]]; then
		log "Copying tlp.conf to /etc/tlp.conf"
		sudo cp "$conf_src" /etc/tlp.conf
		sudo systemctl enable tlp || true
	fi
}

install_kanata() {
	if [[ "$OS" != "arch" ]]; then
		err "kanata is only supported on Arch Linux"
		return 1
	fi

	if command -v yay >/dev/null 2>&1; then
		yay -Sy --noconfirm kanata || true
	else
		log "yay not found, skipping kanata (AUR package)"
		return
	fi

	# uinput is required for kanata to create virtual input devices
	echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf > /dev/null
	sudo modprobe uinput || true

	# User must belong to these groups to read /dev/input and /dev/uinput
	sudo usermod -aG input,uinput "$USER"

	# The package service reads /etc/kanata/kanata.kbd by default.
	# Override it to use the stowed config at ~/.config/kanata/kanata.kbd.
	local cfg="$HOME/.config/kanata/kanata.kbd"
	sudo mkdir -p /etc/systemd/system/kanata.service.d
	sudo tee /etc/systemd/system/kanata.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/kanata --cfg ${cfg}
EOF

	sudo systemctl daemon-reload
	sudo systemctl enable kanata || true
	log "kanata enabled. Log out and back in for group membership changes to take effect."
}

install_intel_undervolt() {
	if [[ "$OS" != "arch" ]]; then
		err "intel-undervolt is only supported on Arch Linux"
		return 1
	fi

	if command -v yay >/dev/null 2>&1; then
		yay -Sy --noconfirm intel-undervolt || true
	else
		log "yay not found, skipping intel-undervolt (AUR package)"
	fi

	local conf_src="$REPO_DIR/intel-undervolt.conf"
	if [[ -f "$conf_src" ]]; then
		log "Copying intel-undervolt.conf to /etc/intel-undervolt.conf"
		sudo cp "$conf_src" /etc/intel-undervolt.conf
	fi
}

install_sddm_theme() {
	if [[ "$OS" != "arch" ]]; then
		err "SDDM theme is only supported on Arch Linux"
		return 1
	fi

	local theme_src="$REPO_DIR/sddm-theme/catppuccin-mocha-lavender"
	local theme_dst="/usr/share/sddm/themes/catppuccin-mocha-lavender"

	if [[ ! -d "$theme_src" ]]; then
		err "SDDM theme not found at $theme_src"
		return 1
	fi

	log "Copying SDDM theme to $theme_dst"
	sudo cp -r "$theme_src" "$theme_dst"
	log "SDDM theme installed"
}

install_nvim() {
	case "$OS" in
		macos)
			brew install neovim ripgrep || true
			;;
		ubuntu)
			sudo apt-get install -y neovim ripgrep || true
			;;
		arch)
			sudo pacman -Sy --noconfirm neovim ripgrep || true
			;;
	esac
}

apply_stow() {
	if ! command -v stow >/dev/null 2>&1; then
		err "stow is not installed. Run the script with privileges or install it first."
		return 1
	fi

	# Packages only relevant on Arch Linux (Hyprland/Wayland stack)
	local arch_only_pkgs="hypr sway swayosd wob waybar mako dunst wallpapers kanata"

	# These configs belong in /etc/, not $HOME — handled by their own install functions
	local etc_pkgs="thinkfan tlp"

	cd "$REPO_DIR"
	for d in */; do
		pkg="${d%/}"
		# Ignore non-dotfile folders
		if [[ "$pkg" == ".git" || "$pkg" == "kde-layouts" || "$pkg" == "sddm-theme" ]]; then
			continue
		fi
		# Code-macos is macOS-only (Library/Application Support path)
		if [[ "$pkg" == "Code-macos" && "$OS" != "macos" ]]; then
			log "Skipping Code-macos (macOS-only)"
			continue
		fi
		# Code (Linux .config path) is not needed on macOS
		if [[ "$pkg" == "Code" && "$OS" == "macos" ]]; then
			log "Skipping Code (use Code-macos on macOS)"
			continue
		fi
		# Skip Arch/Hypr-only packages on other systems
		if [[ "$OS" != "arch" ]] && echo "$arch_only_pkgs" | grep -qw "$pkg"; then
			log "Skipping $pkg (Arch/Hyprland-only)"
			continue
		fi
		# Skip /etc/ packages — they are copied by their install functions, not stowed
		if echo "$etc_pkgs" | grep -qw "$pkg"; then
			log "Skipping $pkg (managed via /etc/, not stow)"
			continue
		fi
		log "Stowing $pkg -> $HOME"
		stow -v -t "$HOME" "$pkg" || log "stow failed for $pkg"
	done
}

main() {
	OS=$(detect_os)
	log "Detected system: $OS"

	case "$OS" in
		macos|ubuntu|arch) ;;
		*) err "Unsupported system (not handled automatically): $OS"; exit 1 ;;
	esac

	# Ask for sudo upfront and keep it alive throughout the script
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

	# Ensure Homebrew is in PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
	if [[ "$OS" == "macos" ]]; then
		if [[ -x /opt/homebrew/bin/brew ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		elif [[ -x /usr/local/bin/brew ]]; then
			eval "$(/usr/local/bin/brew shellenv)"
		else
			log "Homebrew not found. Install it first: https://brew.sh"
			exit 1
		fi
	fi

	if confirm "Install stow?"; then
		install_stow
	else
		log "Skipped stow"
	fi

	if confirm "Install VS Code?"; then
		install_vscode
	else
		log "Skipped VS Code"
	fi

	if confirm "Install VS Code extensions?"; then
		install_vscode_extensions
	else
		log "Skipped VS Code extensions"
	fi

	if confirm "Install kitty?"; then
		install_kitty
	else
		log "Skipped kitty"
	fi

    if confirm "Install Cascadia Code Nerd Font?"; then
        install_cascadia_code_nerd_font
    else
        log "Skipped Cascadia Code Nerd Font"
    fi

	if confirm "Install zsh, Oh My Zsh, and plugins?"; then
		install_zsh_and_oh_my_zsh
	else
		log "Skipped zsh/Oh My Zsh/plugins"
	fi

    if confirm "Install Oh My Posh?"; then
        install_oh_my_posh
    else
        log "Skipped Oh My Posh"
    fi

	if [[ "$OS" == "macos" ]]; then
		if confirm "Apply macOS defaults (input, Finder, Dock, screenshots, Safari)?"; then
			bash "$REPO_DIR/macos-defaults.sh"
		else
			log "Skipped macOS defaults"
		fi
	fi

	if [[ "$OS" == "arch" ]]; then
		if confirm "Install Hyprland stack (hyprland, waybar, dunst, swayosd, playerctl, brightnessctl, hypridle, hyprlock, hyprpaper, grim, slurp, wob, sddm)?"; then
			install_hypr_packages
		else
			log "Skipped Hyprland packages"
		fi

		if confirm "Install SDDM theme (catppuccin-mocha-lavender)?"; then
			install_sddm_theme
		else
			log "Skipped SDDM theme"
		fi

		if confirm "Install intel-undervolt (AUR)?"; then
			install_intel_undervolt
		else
			log "Skipped intel-undervolt"
		fi

		if confirm "Install thinkfan (fan control)?"; then
			install_thinkfan
		else
			log "Skipped thinkfan"
		fi

		if confirm "Install TLP (power management)?"; then
			install_tlp
		else
			log "Skipped TLP"
		fi

		if confirm "Install kanata (keyboard remapper, AUR)?"; then
			install_kanata
		else
			log "Skipped kanata"
		fi
	fi

	if confirm "Install Neovim?"; then
		install_nvim
	else
		log "Skipped Neovim"
	fi

	if confirm "Run stow to symlink dotfiles now?"; then
		apply_stow
	else
		log "Skipped stow. Run 'stow <package>' from $REPO_DIR when you're ready."
	fi

	log "Install completed. Check any error messages above if something failed."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi

