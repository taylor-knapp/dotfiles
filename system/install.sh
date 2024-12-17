#
# Setup Moonlander quick app open shortcuts.
# This trick involves installing and using hammerspoon to link shortcuts that are also mapped by the Moonlander.
#

# Install hammerspoon.
brew install hammerspoon --cask

# Link the currently configured script to the typical services directory.
rm -f ~/.hammerspoon/init.lua
ln -s "$(cd "$(dirname "$0")" && pwd)/init.lua" ~/.hammerspoon

# Close and re-open Hammerspoon to reload the config.
osascript -e 'quit app "Hammerspoon"'
osascript -e 'tell application "Hammerspoon" to activate'