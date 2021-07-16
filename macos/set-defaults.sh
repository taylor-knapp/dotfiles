# Sets macOS defaults.
#
# Defaults exist both globally and for specific applications and are saved in
# ~/Library/Preferences/* as plist files.
#
# Overview of what defaults are: https://macos-defaults.com/
#
# Other implementations
#   - https://github.com/holman/dotfiles/blob/master/macos/set-defaults.sh
#   - https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#
# Run ./set-defaults.sh and close and reopen any affected apps you want the update to take place within.

### Global ###

# Disables press-and-hold for keys (to get accent options) in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

### Finder ###

# Show everything in list view.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Show external hard drives and media on the desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

### Dock ###

# Setup the default look how I like it:
# - left side
# - small tiles with magnification
# - show recent apps
# - do not hide
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 22
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 128
defaults write com.apple.dock show-recents -bool true
defaults write com.apple.dock autohide -bool false


# Run the screensaver if we're in the bottom-left hot corner.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# TODO: Would be really cool to add all my desired apps here by default. Do so after including a script to ensure they are downloaded.
# https://stackoverflow.com/a/59637792/9778071