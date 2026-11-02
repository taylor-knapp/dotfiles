#!/bin/sh

# Install nono
# https://github.com/nolabs-ai/nono
command -v nono >/dev/null || brew install nono

# Resolve the nono directory relative to this script
NONO_DIR="$(cd $(dirname "$0") && pwd)"

# Symlink profiles and config into nono config directory
ln -sfn "$NONO_DIR/profiles" "$HOME/.config/nono/profiles"
ln -sf "$NONO_DIR/config.toml" "$HOME/.config/nono/config.toml"

# Update nono profile json schema to the latest version
nono profile schema > "$NONO_DIR/profile.schema.json"
