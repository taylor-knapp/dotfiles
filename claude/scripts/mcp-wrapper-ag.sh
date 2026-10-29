#!/bin/bash
# Wrapper: fetch fresh OAuth token via client_credentials, run SSE bridge.
# Usage: mcp-wrapper-ag.sh <path-to-env-file>
# Env file must define: SERVER_NAME, MCP_URL, AUTH_URL, SCOPE
# AG_<SERVER_NAME>_SECRET (uppercased, - -> _) holds base64(client_id:secret), exported by nono/claude-nono
# from keystore entry ag_${SERVER_NAME//-/_}

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

# Debug log goes to stderr and a file. Stdout stays free for the MCP stdio protocol.
LOG_FILE="/tmp/claude/mcp-logs/wrapper-$(basename "$ENV_FILE" .env).debug.log"
mkdir -p "$(dirname "$LOG_FILE")"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE" >&2; }
redact() { sed -E 's/("access_token"[[:space:]]*:[[:space:]]*")[^"]*/\1<redacted>/g'; }
trap 'log "ERR at line $LINENO: exit $?"' ERR

log "start: env=$ENV_FILE pid=$$"

# shellcheck disable=SC1090
. "$ENV_FILE"

log "env loaded: SERVER_NAME=${SERVER_NAME:-unset} MCP_URL=${MCP_URL:-unset} AUTH_URL=${AUTH_URL:-unset} SCOPE=${SCOPE:-unset}"

for var in SERVER_NAME MCP_URL AUTH_URL SCOPE; do
  if [ -z "${!var:-}" ]; then
    log "Error: $var not set in $ENV_FILE"
    exit 1
  fi
done

SECRET_VAR="AG_$(printf '%s' "$SERVER_NAME" | tr 'a-z-' 'A-Z_')_SECRET"
CLIENT_SECRET="${!SECRET_VAR:-}"
log "secret var $SECRET_VAR length=${#CLIENT_SECRET}"

if [ -z "$CLIENT_SECRET" ]; then
  log "Error: $SECRET_VAR not set. Add base64(client_id:secret) to the nono keystore and list the account in nono/claude-nono:"
  log "  security add-generic-password -U -s nono -a ag_${SERVER_NAME//-/_} -w <base64>"
  exit 1
fi

# Last line is the HTTP status. Everything before it is the body.
log "token request: POST $AUTH_URL scope=$SCOPE"
HTTP_RESPONSE="$(curl -sS -w '\n%{http_code}' \
  -H "Authorization: Basic $CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=$SCOPE" \
  "$AUTH_URL")" || {
  log "token request failed: curl exit $?"
  exit 1
}

HTTP_CODE="${HTTP_RESPONSE##*$'\n'}"
TOKEN_RESPONSE="${HTTP_RESPONSE%$'\n'*}"
log "token response: http=$HTTP_CODE bytes=${#TOKEN_RESPONSE}"

if [ "$HTTP_CODE" != 200 ]; then
  log "token error body: $(printf '%s' "$TOKEN_RESPONSE" | redact)"
  exit 1
fi

AG_TOKEN="$(printf '%s' "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"

if [ -z "$AG_TOKEN" ]; then
  log "no access_token in response: $(printf '%s' "$TOKEN_RESPONSE" | redact)"
  exit 1
fi
log "access token parsed: length=${#AG_TOKEN}"

export AG_TOKEN
export NODE_USE_ENV_PROXY=1

log "exec bridge: $MCP_URL"
exec node "$SCRIPT_DIR/mcp-sse-bridge.mjs" \
  "$MCP_URL" \
  --header "Authorization: Bearer $AG_TOKEN"
