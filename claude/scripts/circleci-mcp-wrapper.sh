#!/bin/bash
# Wrapper script to load CircleCI token from macOS Keychain and run the MCP server

export CIRCLECI_TOKEN="$(security find-generic-password -s circleci-token -a "$USER" -w 2>/dev/null)"

if [ -z "$CIRCLECI_TOKEN" ]; then
  echo "Error: circleci-token not found in Keychain. Add it with:" >&2
  echo "  security add-generic-password -s circleci-token -a \"\$USER\" -w 'your-token-here'" >&2
  exit 1
fi

npx -y @circleci/mcp-server-circleci@latest
