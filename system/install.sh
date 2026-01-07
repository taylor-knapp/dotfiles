#
# Setup Moonlander quick app open shortcuts.
# This trick involves installing and using hammerspoon to link shortcuts that are also mapped by the Moonlander.
#

# Install hammerspoon.
# brew install hammerspoon --cask

# Link the currently configured script to the typical services directory.
rm -f ~/.hammerspoon/init.lua
ln -s "$(cd "$(dirname "$0")" && pwd)/init.lua" ~/.hammerspoon

# Close and re-open Hammerspoon to reload the config.
osascript -e 'quit app "Hammerspoon"'
osascript -e 'tell application "Hammerspoon" to activate'

#
# Setup default app open shortcuts.
#

# Install duti.
brew reinstall duti

# Assign VSCode default file extensions.
duti -s com.microsoft.VSCode .js all
duti -s com.microsoft.VSCode .jsx all
duti -s com.microsoft.VSCode .ts all
duti -s com.microsoft.VSCode .tsx all
duti -s com.microsoft.VSCode .json all
duti -s com.microsoft.VSCode .md all
duti -s com.microsoft.VSCode .yaml all
duti -s com.microsoft.VSCode .yml all
duti -s com.microsoft.VSCode .tf all
duti -s com.microsoft.VSCode .tfvars all
duti -s com.microsoft.VSCode .hcl all
duti -s com.microsoft.VSCode .zsh all
duti -s com.microsoft.VSCode .sh all
duti -s com.microsoft.VSCode .lua all
duti -s com.microsoft.VSCode .symlink all