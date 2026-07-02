#!/usr/bin/env bash
# Dump the full Ghostty reference into ghostty/ghostty-docs.txt (gitignored).
# One grep-able offline file: config ref + keybind actions + keybinds + themes
# + the bundled markdown docs. See ghostty/CLAUDE.md for how to read it.
#
# Run directly:  bash ghostty/dump-docs.sh   (or via install.sh)
# NOTE: the bundled binary needs Sparkle.framework, which is blocked inside the
# agent sandbox — run this outside the sandbox (e.g. `!` prefix in Claude Code).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/ghostty-docs.txt"
BUNDLE_DOCS="/Applications/Ghostty.app/Contents/Resources/ghostty/docs"

# Prefer a ghostty on PATH; fall back to the macOS app bundle.
if command -v ghostty >/dev/null 2>&1; then
  GB="$(command -v ghostty)"
elif [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  GB="/Applications/Ghostty.app/Contents/MacOS/ghostty"
else
  echo "ghostty binary not found (PATH or /Applications/Ghostty.app). Skipping docs dump." >&2
  exit 0
fi

{
  echo "# Ghostty docs dump — generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Regenerate if older than 30 days. See ghostty/CLAUDE.md."

  echo; echo "===== CONFIG REFERENCE (+show-config --default --docs) ====="
  "$GB" +show-config --default --docs

  echo; echo "===== KEYBIND ACTIONS (+list-actions) ====="
  "$GB" +list-actions

  echo; echo "===== DEFAULT KEYBINDS (+list-keybinds) ====="
  "$GB" +list-keybinds

  echo; echo "===== THEMES (+list-themes) ====="
  "$GB" +list-themes

  echo; echo "===== BUNDLED MARKDOWN DOCS ====="
  if [[ -d "$BUNDLE_DOCS" ]]; then
    find "$BUNDLE_DOCS" \( -name '*.md' -o -name '*.mdx' \) -print 2>/dev/null \
      | sort | while read -r f; do
        echo; echo "----- $f -----"; cat "$f"
      done
  else
    echo "(bundle docs dir not found: $BUNDLE_DOCS)"
  fi
} > "$OUT"

echo "Wrote $OUT ($(wc -l < "$OUT" | tr -d ' ') lines)"
