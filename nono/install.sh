#!/bin/sh

# Install nono
# https://github.com/nolabs-ai/nono
command -v nono >/dev/null || brew install nono

# Agent packs (provide base profiles, e.g. `claude-code`)
nono pull nolabs-ai/claude
nono pull nolabs-ai/opencode

# Keychain-free copy of the claude pack profile (re-run after `nono update`)
"$HOME/.dotfiles/nono/claude-nokeychain.sh"

# Symlink profiles into ~/.config/nono/profiles
mkdir -p "$HOME/.config/nono/profiles"
for f in "$HOME"/.dotfiles/nono/profiles/*.json; do
  ln -sf "$f" "$HOME/.config/nono/profiles/$(basename "$f")"
done
ln -sf "$HOME/.dotfiles/nono/config.toml" "$HOME/.config/nono/config.toml"
