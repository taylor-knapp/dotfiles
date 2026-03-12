# Install iTerm2 shell integration and preferences.
# https://iterm2.com/documentation-shell-integration.html

# The default install can be found below. This file customizes it to only work for zsh and not update my .zshrc.
# Default install: curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

function die() {
  echo "${1}"
  exit 1
}

type printf > /dev/null 2>&1 || die "Shell integration requires the printf binary to be in your path."

URL="https://iterm2.com/shell_integration/zsh"
FILENAME="${HOME}/.iterm2_shell_integration.zsh"

echo "Downloading script from ${URL} and saving it to ${FILENAME}..."

curl -SsL "${URL}" > "${FILENAME}" || die "Couldn't download script from ${URL}"
chmod +x "${FILENAME}"

echo "iterm shell integration installed!"

# --- iTerm2 Preferences ---
# The full plist lives at iterm/com.googlecode.iterm2.plist in this repo.
# We point iTerm's "Load preferences from custom folder" at this directory
# so iTerm reads/writes directly to the repo copy. Commit when you want to
# snapshot for a new machine.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$SCRIPT_DIR"

echo "iTerm preferences configured (loading from $SCRIPT_DIR)."