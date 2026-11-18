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

# Install rtk: https://github.com/rtk-ai/rtk
brew install rtk
rtk init -g --agent claude --auto-patch

# Install colgrep, semantic code search: https://github.com/lightonai/next-plaid#colgrep
brew install lightonai/tap/colgrep
# Register the colgrep plugin with Claude Code. Runs after deploy.sh so the registration lands in the linked settings.json.
colgrep --install-claude-code

# Link config into ~/.claude, merge MCP servers
"$HOME/.dotfiles/claude/deploy.sh"
