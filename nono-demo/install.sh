#!/bin/sh

# Install nono
# https://github.com/nolabs-ai/nono
command -v nono >/dev/null || brew install nono

# Agent packs (provide base profiles, e.g. `claude-code`)
nono pull nolabs-ai/claude

# Resolve the nono directory relative to this script
NONO_DIR="$(cd $(dirname "$0") && pwd)"

# Keychain-free copy of the claude pack profile (re-run after `nono update`)
"$NONO_DIR/claude-nokeychain.sh" > "$NONO_DIR/profiles/nolabs-ai-claude.jsonc"

# Update nono profile json schema to the latest version
nono profile schema > "$NONO_DIR/profile.schema.json"

# Symlink profiles and config into nono config directory
ln -sfn "$NONO_DIR/profiles" "$HOME/.config/nono/profiles"
ln -sf "$NONO_DIR/config.toml" "$HOME/.config/nono/config.toml"
