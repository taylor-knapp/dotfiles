#!/usr/bin/env bash
# Back up AI coding tool configuration before onboarding changes anything.
# Copy-only: never modifies or deletes the originals.
#
# Usage: backup.sh [DEST_DIR]
#   DEST_DIR defaults to ~/.omai-onboarding-backup/<UTC timestamp>
set -euo pipefail

dest="${1:-$HOME/.omai-onboarding-backup/$(date -u +%Y%m%dT%H%M%SZ)}"
umask 077
mkdir -p "$dest"

# Bulky, regenerable runtime state — not configuration.
claude_excludes=(
  --exclude='projects/**' --exclude='todos/' --exclude='shell-snapshots/'
  --exclude='statsig/' --exclude='telemetry/' --exclude='debug/'
  --exclude='file-history/' --exclude='paste-cache/' --exclude='session-env/'
  --exclude='ide/' --exclude='cache/' --exclude='.omai-onboarding-backup/'
)

backed_up=()

copy_dir() { # <src> <name> [rsync args...]
  local src="$1" name="$2"; shift 2
  [ -d "$src" ] || return 0
  mkdir -p "$dest/$name"
  rsync -a "$@" "$src/" "$dest/$name/"
  backed_up+=("$src")
}

copy_file() { # <src> <name>
  [ -f "$1" ] || return 0
  cp -p "$1" "$dest/$2"
  backed_up+=("$1")
}

# Claude Code: config tree, plus per-project auto-memory (which lives under
# projects/ next to the large session transcripts we skip).
copy_dir "$HOME/.claude" claude \
  --include='projects/' --include='projects/*/' \
  --include='projects/*/memory/' --include='projects/*/memory/**' \
  "${claude_excludes[@]}"
copy_file "$HOME/.claude.json" claude.json

# OpenCode: config dir only. ~/.local/share/opencode holds credentials and
# session history; deliberately left out.
copy_dir "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" opencode

# omai itself (profiles, custom overlays, state).
copy_dir "${XDG_CONFIG_HOME:-$HOME/.config}/oh-my-ai-shell" oh-my-ai-shell

# Other tools omai can target — only if present.
copy_dir "$HOME/.codex" codex --exclude='sessions/' --exclude='log/' --exclude='auth.json'
copy_dir "$HOME/.copilot" copilot --exclude='session-state/' --exclude='logs/'

# Cursor (not an omai target, but backed up and migratable). ~/.cursor holds
# MCP config, commands and rules; editor settings live under Application Support.
copy_dir "$HOME/.cursor" cursor --exclude='extensions/' --exclude='projects/' --exclude='ai-tracking/' --exclude='*.log'
cursor_user="$HOME/Library/Application Support/Cursor/User"
for f in settings.json keybindings.json; do
  if [ -f "$cursor_user/$f" ]; then mkdir -p "$dest/cursor-user"; cp -p "$cursor_user/$f" "$dest/cursor-user/$f"; backed_up+=("$cursor_user/$f"); fi
done
copy_dir "$cursor_user/snippets" cursor-user/snippets

if [ ${#backed_up[@]} -eq 0 ]; then
  echo "Nothing to back up: no agent tool configuration found."
  rmdir "$dest" 2>/dev/null || true
  exit 0
fi

chmod -R go-rwx "$dest"
echo "Backup written to: $dest"
echo "Contains (may include secrets — keep it private):"
printf '  %s\n' "${backed_up[@]}"
echo "Restore example: rsync -a \"$dest/claude/\" ~/.claude/"
