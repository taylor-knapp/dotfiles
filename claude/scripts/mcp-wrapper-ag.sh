#!/bin/bash
# Wrapper: fetch fresh OAuth token via client_credentials, run SSE bridge.
# Usage: mcp-wrapper-ag.sh <path-to-env-file>
# Env file must define: SERVER_NAME, CLIENT_ID, MCP_URL, AUTH_URL, SCOPE
# Client secret read from env var AG_<SERVER_NAME>_CLIENT_SECRET (uppercased, - -> _),
# injected by nono from keystore entry ag-${SERVER_NAME} (profile nono/profiles/mcp.jsonc)

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

SECRET_VAR="AG_$(printf '%s' "$SERVER_NAME" | tr 'a-z-' 'A-Z_')_CLIENT_SECRET"
CLIENT_SECRET="${!SECRET_VAR:-}"

if [ -z "$CLIENT_SECRET" ]; then
  echo "Error: $SECRET_VAR not set. Add the secret to the nono keystore with:" >&2
  echo "  security add-generic-password -U -s nono -a ag-$SERVER_NAME -w" >&2
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
