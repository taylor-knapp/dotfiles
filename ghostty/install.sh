# Symlink the Ghostty config into place.
# Ghostty reads ~/.config/ghostty/config (XDG path, works on macOS too).
# We symlink the repo copy so edits are version-controlled.
#
# Ghostty auto-injects zsh shell integration — no download step needed
# (unlike iTerm). tab.zsh is auto-sourced by the dotfiles loader.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${HOME}/.config/ghostty"

mkdir -p "$CONFIG_DIR"
ln -sf "$SCRIPT_DIR/config" "$CONFIG_DIR/config"

echo "Ghostty config symlinked: $CONFIG_DIR/config -> $SCRIPT_DIR/config"

# Generate the offline docs dump (gitignored). Best-effort — won't fail install
# if ghostty isn't installed yet.
bash "$SCRIPT_DIR/dump-docs.sh" || echo "Docs dump skipped." >&2

# Schedule a daily refresh so the dump tracks Ghostty upgrades automatically.
# Idempotent: a marker comment lets us replace our line without touching others.
if command -v crontab >/dev/null 2>&1; then
  CRON_MARK="# ghostty-dump-docs (managed by dotfiles)"
  CRON_LINE="0 9 * * * /bin/bash $SCRIPT_DIR/dump-docs.sh >/dev/null 2>&1 $CRON_MARK"
  ( crontab -l 2>/dev/null | grep -vF "$CRON_MARK"; echo "$CRON_LINE" ) | crontab -
  echo "Cron installed: daily docs refresh at 09:00 (remove with 'crontab -e')."
else
  echo "crontab not available — skipping daily docs refresh." >&2
fi

echo "Reload in Ghostty with: cmd+shift+, (or restart)"
