#!/bin/sh
#
# Brave Browser
#
# Installs Brave and sets it as the default browser.

brew install --cask brave-browser

# Install defaultbrowser CLI and set Brave as default
# (triggers macOS confirmation dialog)
brew install defaultbrowser
defaultbrowser browser
