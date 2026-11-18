#!/bin/sh

# --- Install Overview
# 1. Install nono (Homebrew, or the install script if Homebrew is missing or fails).
# 2. Pull the agent packs (provide base profiles).
# 3. Keep ~/.claude/settings.json linked to its source file (if it was a symlink).
# 4. Copy the claude pack profile to a keychain-free version (re-run after `nono update`).
# 5. Copy the sandbox npm config (lib/npmrc) to ~/.nono.npmrc.
# 6. Install lib/nono-gcp-npm-token-helper to ~/bin.
# 7. Symlink the claude-nono launcher to ~/bin/clno.
# 8. Update nono profile json schema to the latest version.
# 9. Symlink profiles into nono config directory.
# 10. Setup dedicated gnupg key for claude for signed commits.
# ---

# Install nono
# https://github.com/nolabs-ai/nono
# Homebrew can fail (seen on Intel Macs), so fall back to the install script.
if ! command -v nono >/dev/null; then
  if ! (command -v brew >/dev/null && brew install nono); then
    curl -fsSL https://nono.sh/install.sh | sh
  fi
fi

# --- Keep ~/.claude/settings.json linked to its source file -------------
# `nono pull` can replace a symlinked ~/.claude/settings.json with a plain file.
# If the file was a symlink, restore the link after the pull.
# If it was never a symlink, do nothing.

SETTINGS="$HOME/.claude/settings.json"

# 1. If settings.json is a symlink, find the file it links to (the origin).
if [ -L "$SETTINGS" ]; then
  SETTINGS_ORIGIN="$(readlink -f "$SETTINGS")"
fi

# 2. Pull the agent packs (provide base profiles, e.g. `claude-code`).
nono pull nolabs-ai/claude

# If there was a link and the pull broke it:
#   3. Copy the settings that nono wrote back to the origin file.
#   4. Point settings.json at the origin file again.
if [ -n "$SETTINGS_ORIGIN" ] && [ ! -L "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS_ORIGIN"
  ln -sf "$SETTINGS_ORIGIN" "$SETTINGS"
fi

# -------------------------------------------------------------------------

# Resolve the nono directory relative to this script
NONO_DIR="$(cd $(dirname "$0") && pwd)"

# Sandbox npm config. The commercetools profile points pnpm at ~/.nono.npmrc.
cp "$NONO_DIR/lib/npmrc" "$HOME/.nono.npmrc"

# GCP token helper for the gcp_npm credential (commercetools profile runs $HOME/bin/nono-gcp-npm-token-helper).
mkdir -p "$HOME/.nono/bin"
install -m 755 "$NONO_DIR/lib/nono-gcp-npm-token-helper" "$HOME/.nono/bin/nono-gcp-npm-token-helper"

# clno launcher. Symlink, not a copy: claude-nono finds .env through its own real path.
ln -sf "$NONO_DIR/claude-nono" "$HOME/.nono/bin/clno"

# Keychain-free copy of the claude pack profile (re-run after `nono update`)
"$NONO_DIR/lib/claude-nokeychain.sh" > "$NONO_DIR/profiles/nolabs-ai-claude.jsonc"

# Placeholder personal profile (gitignored; claude-code extends it)
[ -f "$NONO_DIR/profiles/personal.jsonc" ] || cat > "$NONO_DIR/profiles/personal.jsonc" <<'EOF'
{
  "$schema": "../profile.schema.json",
  "meta": { "name": "personal", "description": "Machine-specific overrides." }
}
EOF

# Update nono profile json schema to the latest version
nono profile schema > "$NONO_DIR/profile.schema.json"

# Symlink profiles into nono config directory
mkdir -p "$HOME/.config/nono"
ln -sfn "$NONO_DIR/profiles" "$HOME/.config/nono/profiles"

# Setup dedicated gnupg key for claude for signed commits
"$NONO_DIR/lib/setup-claude-gpg.sh"

# clno needs $HOME/.nono/bin on PATH. Add it to ~/.zshrc once (idempotent).
PATH_LINE='export PATH="$HOME/.nono/bin:$PATH"'
case ":$PATH:" in
  *":$HOME/.nono/bin:"*) ;;
  *)
    if ! grep -qsF "$PATH_LINE" "$HOME/.zshrc"; then
      printf '\n%s\n' "$PATH_LINE" >> "$HOME/.zshrc"
      echo "Added $HOME/.nono/bin to PATH in ~/.zshrc. Run: source ~/.zshrc (or open a new shell)."
    fi
    ;;
esac
