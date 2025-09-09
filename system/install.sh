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

# Assign Cursor default file extensions.
duti -s com.todesktop.230313mzl4w4u92 .js all
duti -s com.todesktop.230313mzl4w4u92 .jsx all
duti -s com.todesktop.230313mzl4w4u92 .ts all
duti -s com.todesktop.230313mzl4w4u92 .tsx all
duti -s com.todesktop.230313mzl4w4u92 .json all
duti -s com.todesktop.230313mzl4w4u92 .md all
duti -s com.todesktop.230313mzl4w4u92 .yaml all
duti -s com.todesktop.230313mzl4w4u92 .yml all
duti -s com.todesktop.230313mzl4w4u92 .tf all
duti -s com.todesktop.230313mzl4w4u92 .tfvars all
duti -s com.todesktop.230313mzl4w4u92 .hcl all
duti -s com.todesktop.230313mzl4w4u92 .zsh all
duti -s com.todesktop.230313mzl4w4u92 .sh all
duti -s com.todesktop.230313mzl4w4u92 .lua all
duti -s com.todesktop.230313mzl4w4u92 .symlink all