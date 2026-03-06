# Install fnm (Fast Node Manager) and migrate from NVM if present.

# 1. Install fnm
if ! command -v fnm >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "  Installing fnm via Homebrew..."
    brew install fnm
  else
    echo "  Install fnm manually: https://github.com/Schniz/fnm#installation"
    exit 1
  fi
fi

# 2. Bootstrap fnm in this shell (dotfiles sourcing hasn't happened yet)
eval "$(fnm env --shell bash)"

# 3. Install a current LTS node as default if fnm has no versions yet
if [ -z "$(fnm list 2>/dev/null | grep -v 'system')" ]; then
  echo "  Installing latest Node LTS via fnm..."
  fnm install --lts
  fnm default lts-latest
fi

# 4. Migrate NVM default if NVM is still around and fnm default isn't set
if [ -d "$HOME/.nvm" ]; then
  echo ""
  echo "  NVM detected at ~/.nvm"
  echo "  fnm reads .nvmrc files natively — versions auto-install on first cd."
  echo "  You can remove ~/.nvm when ready:  rm -rf ~/.nvm"
  echo ""
fi
