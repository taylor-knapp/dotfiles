#!/bin/bash
# Wrapper script to run the CircleCI MCP server. CIRCLECI_TOKEN is a phantom injected by nono (profile nono/profiles/mcp.jsonc), and the proxy swaps in the real token from keystore account circleci_token

if [ -z "${CIRCLECI_TOKEN:-}" ]; then
  echo "Error: CIRCLECI_TOKEN not set. Add a route for circleci in nono/profiles/mcp.jsonc and store the token in the keystore with:" >&2
  echo "  security add-generic-password -U -s nono -a circleci_token -w" >&2
  exit 1
fi

export NODE_USE_ENV_PROXY=1

npx -y @circleci/mcp-server-circleci@latest
