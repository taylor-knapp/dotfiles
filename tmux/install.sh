#!/bin/sh
#
# tmux
#
# Installs tmux, TPM (plugin manager), and plugins.

# 1. Symlink config (needed before TPM can read plugin list)
CONF_SRC="$(cd "$(dirname "$0")" && pwd)/tmux.conf.symlink"
if [ ! -L "$HOME/.tmux.conf" ]; then
  echo "  Symlinking ~/.tmux.conf..."
  ln -sf "$CONF_SRC" "$HOME/.tmux.conf"
fi

# 2. Install tmux
if ! command -v tmux >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "  Installing tmux via Homebrew..."
    brew install tmux
  else
    echo "  Install tmux manually: https://github.com/tmux/tmux"
    exit 1
  fi
fi

# 3. Install TPM (Tmux Plugin Manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "  Cloning TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# 4. Install plugins headlessly
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  echo "  Installing tmux plugins..."
  "$TPM_DIR/bin/install_plugins"
fi
