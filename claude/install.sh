#!/bin/sh
#
# Install Claude Code, packages, and link configuration to ~/.claude

# https://code.claude.com/docs/en/quickstart
curl -fsSL https://claude.ai/install.sh | bash
# https://github.com/ccusage/ccusage
brew install ccusage
# https://github.com/JuliusBrussee/caveman
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
# https://github.com/AminBlg/SimpleEnglish
claude plugin marketplace add AminBlg/SimpleEnglish && claude plugin install simple-english@simple-english

# Dedicated keychain for claude/shim/security (prompts for a password), no auto-lock timeout
kc="$(cd "$(dirname "$0")" && pwd)/.claude.keychain.db"  # gitignored
[ -s "$kc" ] || { rm -f "$kc"; security create-keychain -P "$kc"; }  # empty file = aborted create
security set-keychain-settings "$kc"

# Link config into ~/.claude, merge MCP servers
"$HOME/.dotfiles/claude/deploy.sh"
