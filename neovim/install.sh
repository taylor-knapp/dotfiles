#!/bin/sh
#
# neovim
#
# Installs Neovim + tools the config expects, and symlinks
# neovim/config -> ~/.config/nvim.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/config"
CONFIG_DST="$HOME/.config/nvim"

# 1. Install neovim and dependencies
if command -v brew >/dev/null 2>&1; then
  for pkg in neovim ripgrep tree-sitter-cli; do
    brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
  done
else
  echo "  Install neovim manually: https://neovim.io"
fi

# 2. Symlink config (back up any existing non-symlink config)
mkdir -p "$HOME/.config"
if [ -e "$CONFIG_DST" ] && [ ! -L "$CONFIG_DST" ]; then
  backup="$CONFIG_DST.backup.$(date +%Y%m%d%H%M%S)"
  echo "  Backing up existing $CONFIG_DST -> $backup"
  mv "$CONFIG_DST" "$backup"
fi
ln -sfn "$CONFIG_SRC" "$CONFIG_DST"
echo "  Neovim config symlinked: $CONFIG_DST -> $CONFIG_SRC"
