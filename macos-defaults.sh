#!/usr/bin/env bash
set -euo pipefail

# macOS system preferences via `defaults write`
#
# Configures: input, Finder, Dock, screenshots, Safari, Software Update,
# and quality-of-life tweaks. Each block includes the GUI path equivalent.
#
# Safe to run multiple times (idempotent). Closes System Settings before
# writing to prevent it from overriding changes.

log() { echo "[macos-defaults] $*"; }

# Close System Settings to prevent it from overwriting our changes
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ── Input ──────────────────────────────────────────────────────────────

# System Settings > Mouse/Trackpad > Natural scrolling → off
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# System Settings > Keyboard > Press and hold → key repeat instead of accent popup
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# System Settings > Keyboard > Text Input > Corrections
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# System Settings > Trackpad > Point & Click > Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Finder ─────────────────────────────────────────────────────────────

# Finder > Settings > Advanced > Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Cmd+Shift+. (toggle hidden files)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder > View > Show Status Bar / Show Path Bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Finder > View > as Columns
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Finder > Settings > Advanced > When performing a search → Search the Current Folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Finder > Settings > Advanced > Show warning before changing an extension → off
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder > Settings > General > New Finder windows show → Home folder
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Prevent .DS_Store on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Dock ───────────────────────────────────────────────────────────────

# Remove all pinned apps except Safari (Finder is always present)
defaults write com.apple.dock persistent-apps -array \
	'<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Safari.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults write com.apple.dock persistent-others -array

# System Settings > Desktop & Dock > Automatically hide and show the Dock → on
defaults write com.apple.dock autohide -bool true
# System Settings > Desktop & Dock > (no GUI) auto-hide delay & animation speed
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# System Settings > Desktop & Dock > Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# System Settings > Desktop & Dock > Show recent applications in Dock → off
defaults write com.apple.dock show-recents -bool false

# ── Screenshots ────────────────────────────────────────────────────────

# Screenshot.app > Options > Save to
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ── Software Update ───────────────────────────────────────────────────

# System Settings > General > Software Update > Automatic updates
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# ── Safari ─────────────────────────────────────────────────────────────

# Safari > View > Show Status Bar
defaults write com.apple.Safari ShowOverlayStatusBar -bool true
# Safari > Settings > Advanced > Smart Search Field > Show full website address
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
# Safari > Settings > Advanced > Show features for web developers
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# ── Quality of life ───────────────────────────────────────────────────

# Expand save/print panels by default (no GUI equivalent)
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# System Settings > (no GUI) save to disk, not iCloud, by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false


# ── Restart affected processes ─────────────────────────────────────────

log "Restarting affected processes..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

log "Done. Some changes may require a logout/restart to take full effect."
