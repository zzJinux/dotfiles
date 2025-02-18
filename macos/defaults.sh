#!/usr/bin/env bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# References
# https://github.com/mathiasbynens/dotfiles/blob/ea68bda80a455e149d29156071d4c8472f6b93cb/.macos
# https://macos-defaults.com/

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` timestamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# To check current values:
# cat macos/defaults.sh | grep '^defaults write' | awk '{ print $1, "read", $3, $4 }' | while IFS=$'\n' read -r a; do echo "$a"; printf '  '; eval "$a"; done

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Save to disk (not to iCloud) by default
defaults write -g "NSDocumentSaveNewDocumentsToCloud" -bool false 

# Appearance: Light
{
  defaults delete -g AppleInterfaceStyle 2>/dev/null
  defaults delete -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null
}

# Disable automatic period substitution as it’s annoying when typing code
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable auto-correct
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# Dragging windows from anywhere (Command+Control and drag)
defaults write -g NSWindowShouldDragOnGesture -bool true

# Disable window animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false


###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Dock
{
  # Put the Dock on the bottom
  defaults write com.apple.dock orientation -string bottom

  # Set the icon size of a Dock item
  defaults write com.apple.dock tilesize -int 48

  # Turn on Dock autohide
  defaults write com.apple.dock autohide -bool true

  # Change minimize/maximize window effect (suck: hidden value)
  defaults write com.apple.dock mineffect -string suck
}

# Don’t group windows by application in Mission Control
# (i.e. use the old Exposé behavior instead)
defaults write com.apple.dock expose-group-by-app -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false


# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen

# Top left screen corner w/ Cmd → Put display to sleep
defaults write com.apple.dock wvous-tl-corner -int 10
defaults write com.apple.dock wvous-tl-modifier -int 1048576 # Cmd
# Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom left screen corner → Mission Control
defaults write com.apple.dock wvous-bl-corner -int 2
defaults write com.apple.dock wvous-bl-modifier -int 0
# Bottom left screen corner → Application windows
defaults write com.apple.dock wvous-br-corner -int 3
defaults write com.apple.dock wvous-br-modifier -int 0

# Show macOS app switcher across all monitors
defaults write com.apple.dock appswitcher-all-displays -bool true

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write -g AppleKeyboardUIMode -int 3

# Key repeat
{
  # Disable press-and-hold for keys in favor of key repeat
  defaults write -g ApplePressAndHoldEnabled -bool false

  # Set a blazingly fast keyboard repeat rate
  defaults write -g KeyRepeat -int 2
  defaults write -g InitialKeyRepeat -int 25
}

# Press 🌐 to show Emoji & Symbols
defaults write com.apple.HIToolbox AppleFnUsageType -int 2

# Enable: Use F1, F2, etc. keys as standard function keys
defaults write -g com.apple.keyboard.fnState -bool true

# Enable "Silent clicking"
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0

# Enable "Swipe between pages"
defaults write -g AppleEnableSwipeNavigateWithScrolls -bool true
defaults write TrackpadFourFingerHorizSwipeGesture -int 2
defaults write TrackpadThreeFingerHorizSwipeGesture -int 2

# App Expose = swipe down with three fingers
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

# Shortcuts
{
  "$SCRIPT_DIR"/defaults_shortcuts.py
}


###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: show all filename extensions
defaults write -g AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write -g com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write -g com.apple.springing.delay -float 0.5


for app in "Activity Monitor" \
  "cfprefsd" \
  "Dock" \
  "Finder" \
  "SystemUIServer"; do
  killall "${app}" >/dev/null 2>/dev/null
done

/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "Done. Note that some of these changes require a logout/restart to take effect."
