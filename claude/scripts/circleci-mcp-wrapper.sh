#!/bin/bash
# Wrapper script to run the CircleCI MCP server. CIRCLECI_TOKEN is injected by nono from the keystore (profile nono/profiles/mcp.jsonc)

if [ -z "${CIRCLECI_TOKEN:-}" ]; then
  echo "Error: CIRCLECI_TOKEN not set. Add the token to the nono keystore with:" >&2
  echo "  security add-generic-password -U -s nono -a circleci-token -w" >&2
  exit 1
fi

npx -y @circleci/mcp-server-circleci@latest
