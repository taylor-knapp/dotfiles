#!/bin/sh
#
# Install Claude Code

if test "$(uname)" = "Darwin"; then
  # https://code.claude.com/docs/en/quickstart
  curl -fsSL https://claude.ai/install.sh | bash
fi
