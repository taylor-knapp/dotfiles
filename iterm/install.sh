# Install iterm shell integration.
# https://iterm2.com/documentation-shell-integration.html

# todo: there are some plist files I have saved to dropbox that should really be added here instead.


# The default install can be found below. This file customizes it to only work for zsh and not update my .zshrc.
# Default install: curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

function die() {
  echo "${1}"
  exit 1
}

type printf > /dev/null 2>&1 || die "Shell integration requires the printf binary to be in your path."

URL="https://iterm2.com/shell_integration/zsh"
SCRIPT="${HOME}/.zshrc"
FILENAME="${HOME}/.iterm2_shell_integration.zsh"

echo "Downloading script from ${URL} and saving it to ${FILENAME}..."

curl -SsL "${URL}" > "${FILENAME}" || die "Couldn't download script from ${URL}"
chmod +x "${FILENAME}"

echo "iterm shell integration installed!"

# Enable the Python API server (used by gw-layout for pane management)
defaults write com.googlecode.iterm2 EnableAPIServer -bool true

# New panes/tabs reuse the working directory of the current session
/usr/libexec/PlistBuddy -c "Set ':New Bookmarks:0:Custom Directory' Recycle" ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null

# Tab title: show only session name (set by tab.zsh), removes "(-zsh)" job suffix.
# Uses iTerm's Python API (via gw-layout's shared venv) so it applies immediately.
"$(dirname "$0")/set-title-components.py"