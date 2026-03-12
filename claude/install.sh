#!/bin/sh
#
# Install Claude Code and agent-safehouse

if test "$(uname)" = "Darwin"; then
  # https://code.claude.com/docs/en/quickstart
  curl -fsSL https://claude.ai/install.sh | bash
  # https://agent-safehouse.dev/
  if ! command -v safehouse >/dev/null 2>&1; then
    brew install eugene1g/safehouse/agent-safehouse
  elif brew list eugene1g/safehouse/agent-safehouse >/dev/null 2>&1; then
    brew upgrade eugene1g/safehouse/agent-safehouse
  else
    echo "safehouse is installed but not via Homebrew — skipping update" >&2
  fi
fi
