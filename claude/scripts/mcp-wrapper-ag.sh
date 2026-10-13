#!/bin/bash
# Wrapper: fetch fresh OAuth token via client_credentials, run SSE bridge.
# Usage: mcp-wrapper-ag.sh <path-to-env-file>
# Env file must define: SERVER_NAME, CLIENT_ID, MCP_URL, AUTH_URL, SCOPE
# Client secret read from Keychain entry: ag-${SERVER_NAME}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ENV_FILE="${1:-}"

if [ -z "$ENV_FILE" ]; then
  echo "Usage: $0 <env-file>" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: env file not found: $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

for var in SERVER_NAME CLIENT_ID MCP_URL AUTH_URL SCOPE; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var not set in $ENV_FILE" >&2
    exit 1
  fi
done

KEYCHAIN_SERVICE="ag-${SERVER_NAME}"
CLIENT_SECRET="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w 2>/dev/null || true)"

if [ -z "$CLIENT_SECRET" ]; then
  echo "Error: $KEYCHAIN_SERVICE client secret not found in Keychain. Add it with:" >&2
  echo "  security add-generic-password -U -s $KEYCHAIN_SERVICE -a \"\$USER\" -w 'your-client-secret'" >&2
  exit 1
fi

TOKEN_RESPONSE="$(curl -sS -f \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=$SCOPE" \
  "$AUTH_URL")" || {
  echo "Error: token request failed" >&2
  echo "$TOKEN_RESPONSE" >&2
  exit 1
}

AG_TOKEN="$(printf '%s' "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"

if [ -z "$AG_TOKEN" ]; then
  echo "Error: no access_token in response: $TOKEN_RESPONSE" >&2
  exit 1
fi

export AG_TOKEN
export NODE_USE_ENV_PROXY=1

exec node "$SCRIPT_DIR/mcp-sse-bridge.mjs" \
  "$MCP_URL" \
  --header "Authorization: Bearer $AG_TOKEN"
