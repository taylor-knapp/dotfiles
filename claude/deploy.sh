#!/bin/bash
# Link Claude Code config from this topic into ~/.claude and merge MCP servers.
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

mkdir -p "$CLAUDE_HOME/skills"

ln -sf "$REPO_DIR/AGENTS.md" "$CLAUDE_HOME/CLAUDE.md"
ln -sf "$REPO_DIR/settings.json" "$CLAUDE_HOME/settings.json"

# Replace mcpServers in ~/.claude.json with mcp.json
CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$CLAUDE_JSON" ]; then
    cp "$CLAUDE_JSON" "$CLAUDE_JSON.backup"
    jq -s '.[0] + {mcpServers: .[1].mcpServers}' "$CLAUDE_JSON" "$REPO_DIR/mcp.json" > "$CLAUDE_JSON.tmp"
    mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    echo "  Replaced mcpServers in ~/.claude.json with mcp.json"
else
    echo "  Warning: ~/.claude.json not found, skipping MCP merge"
fi

# Drop broken skill symlinks and any left over from the old claudie repo
find "$CLAUDE_HOME/skills" -maxdepth 1 -type l \( ! -exec test -e {} \; -o -lname "$HOME/code/claudie/*" \) -delete

for skill in "$REPO_DIR/skills"/*/; do
    ln -sfn "${skill%/}" "$CLAUDE_HOME/skills/$(basename "$skill")"
    echo "  Linked skill: $(basename "$skill")"
done
