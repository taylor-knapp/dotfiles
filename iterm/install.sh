# Install iterm shell integration.
# https://iterm2.com/documentation-shell-integration.html

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